[![Gem Version](https://badge.fury.io/rb/activestorage-sftp.svg)](https://badge.fury.io/rb/activestorage-sftp)

Remote DiskService through SFTP, for ActiveStorage. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activestorage-sftp'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activestorage-sftp

## Usage

Each application server saves blobs to file server through SFTP:

```yml
# config/storage.yml
sftp:
  service: SFTP
  user: user
  root: /var/www/proj/shared/storage
  host: file.intranet
  public_host: https://file.internet
  password: <%= ENV['PASSWORD'] %> # optional
```

File server serves blobs using DiskService:
```yml
# config/storage.yml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
```

Or use it as backup for your primary service:
```yml
# config/storage.yml
mirrored:
  service: Mirror
  primary: local #/S3/AzureStorage/GCS
  mirrors:
    - sftp
sftp:
  service: SFTP
  user: user
  root: /etc/backup/proj
  host: secure.backup
```

### use_public_url: Generate plain ("dumb") URLs of upload server

By default the generated URLs will include parameters for `content_disposition`, expiration hints etc.  A generated blobs URL might thus look like:

    https://publichost/PATH/rails/active_storage/disk/hash-hash/name.JPG?content_type=image%2Fjpeg&disposition=inline%3B+filename%3D

If you prefer simple URLs like

    https://publichost/PATH/hash

you can set a configuration option:

```yml
# config/storage.yml
sftp:
  service: SFTP
  user: user
  root: /var/www/proj/shared/storage
  host: file.intranet
  public_host: https://file.internet
  simple_public_urls: true
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/treenewbee/activestorage-sftp.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
