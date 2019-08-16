require "active_storage/sftp/version"
require "active_storage/service/sftp_service"

module ActiveStorage
  module SFTP
    class Error < StandardError; end
    class ChunkSizeError < Error; end
    class SFTPResponseError < Error; end
  end
end
