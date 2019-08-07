require "net/sftp"
require "digest/md5"
require "active_support/core_ext/numeric/bytes"

module ActiveStorage
  # Wraps a remote path as an Active Storage service. See ActiveStorage::Service for the generic API
  # documentation that applies to all services.
  class Service::SFTPService < Service

    MAX_CHUNK_SIZE = 64.kilobytes.freeze

    attr_reader :host, :user, :root, :public_host

    def initialize(host:, user:, public_host: nil, root: './')
      @host = host
      @user = user
      @root = root
      @public_host = public_host
    end

    def upload(key, io, checksum: nil, **)
      instrument :upload, key: key, checksum: checksum do
        ensure_integrity_of(io, checksum) if checksum
        mkdir_for(key)
        through_sftp do |sftp|
          sftp.upload!(io.path, path_for(key))
        end
      end
    end

    def download(key, chunk_size: MAX_CHUNK_SIZE, &block)
      if chunk_size > MAX_CHUNK_SIZE
        # TODO Error
        raise "Maximum chunk size: #{MAX_CHUNK_SIZE}"
      end
      if block_given?
        instrument :streaming_download, key: key do
          through_sftp do |sftp|
            file = sftp.open!(path_for(key))
            buf = StringIO.new
            pos = 0
            eof = false
            until eof do
              request = sftp.read(file, pos, chunk_size) do |response|
                if response.eof?
                  eof = true
                elsif !response.ok?
                  # TODO Error
                  raise "SFTP Response Error"
                else
                  chunk = response[:data]
                  block.call(chunk)
                  buf << chunk
                  pos += chunk.size
                end
              end
              request.wait
            end
            sftp.close(file)
            buf.string
          end
        end
      else
        instrument :download, key: key do
          io = StringIO.new
          through_sftp do |sftp|
            sftp.download!(path_for(key), io)
          end
          io.string
        rescue Errno::ENOENT
          raise ActiveStorage::FileNotFoundError
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        if range.size > MAX_CHUNK_SIZE
          # TODO Error
          raise "Maximun chunk size: #{MAX_CHUNK_SIZE}"
        end
        chunk = StringIo.new
        through_sftp do |sftp|
          sftp.open(path_for(key)) do |file|
            chunk << sftp.read(file, range.begin, ranage.size).response[:data]
          end
        end
        chunk.string
      rescue Errno::ENOENT
        raise ActiveStorage::FileNotFoundError
      end
    end

    def delete(key)
      instrument :delete, key: key do
        through_sftp do |sftp|
          sftp.remove!(path_for(key))
        end
      rescue Net::SFTP::StatusException
        # Ignore files already deleted
      end
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: prefix do
        through_sftp do |sftp|
          sftp.dir.glob(root, "#{prefix}*") do |entry|
            begin
              sftp.remove!(entry.path)
            rescue Net::SFTP::StatusException
              # Ignore files already deleted
            end
          end
        end
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        answer = false
        through_sftp do |sftp|
          answer = sftp.stat(path_for(key)).present?
        end
        payload[:exist] = answer
        answer
      end
    end

    def url(key, expires_in:, filename:, disposition:, content_type:)
        instrument :url, key: key do |payload|
          raise "public_host not defined." unless public_host
          content_disposition = content_disposition_with(type: disposition, filename: filename)
          verified_key_with_expiration = ActiveStorage.verifier.generate(
              {
                  key: key,
                  disposition: content_disposition,
                  content_type: content_type
              },
              { expires_in: expires_in,
                purpose: :blob_key }
          )

          generated_url = url_helpers.rails_disk_service_url(verified_key_with_expiration,
                                                             host: public_host,
                                                             disposition: content_disposition,
                                                             content_type: content_type,
                                                             filename: filename
          )
          payload[:url] = generated_url

          generated_url
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
      instrument :url, key: key do |payload|
        verified_token_with_expiration = ActiveStorage.verifier.generate(
            {
                key: key,
                content_type: content_type,
                content_length: content_length,
                checksum: checksum
            },
            { expires_in: expires_in,
              purpose: :blob_token }
        )

        generated_url = url_helpers.update_rails_disk_service_url(verified_token_with_expiration,
                                                                  host: public_host
        )

        payload[:url] = generated_url

        generated_url
      end
    end

    def headers_for_direct_upload(key, content_type:, **)
      { "Content-Type" => content_type }
    end

    protected
      def through_sftp(&block)
        Net::SFTP.start(@host, @user) do |sftp|
          block.call(sftp)
        end
      end

      def path_for(key)
        File.join folder_for(key), key
      end

      def folder_for(key)
        File.join root, relative_folder_for(key)
      end

      def relative_folder_for(key)
        [ key[0..1], key[2..3] ].join("/")
      end

      def mkdir_for(key)
        through_sftp do |sftp|
          sub_folder = File.join root, key[0..1]
          begin
            sftp.opendir!(sub_folder)
          rescue => e
            sftp.mkdir!(sub_folder)
          end
          sub_folder = File.join(sub_folder, key[2..3])
          begin
            sftp.opendir!(sub_folder)
          rescue => e
            sftp.mkdir!(sub_folder)
          end
        end
      end

      def ensure_integrity_of(io, checksum)
        unless Digest::MD5.new.update(io.read).base64digest == checksum
          delete key
          raise ActiveStorage::IntegrityError
        end
      end

      def url_helpers
        @url_helpers ||= Rails.application.routes.url_helpers
      end
  end
end
