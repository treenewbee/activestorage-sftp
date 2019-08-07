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


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/treenewbee/activestorage-sftp.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
