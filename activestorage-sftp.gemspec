
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_storage/sftp/version"

Gem::Specification.new do |spec|
  spec.name          = "activestorage-sftp"
  spec.version       = ActiveStorage::SFTP::VERSION
  spec.authors       = ["treenewbee"]
  spec.email         = ["yangguchen@gmail.com"]

  spec.summary       = %q{SFTP Service for ActiveStorage}
  spec.description   = %q{SFTP Service for ActiveStorage}
  spec.homepage      = "https://github.com/treenewbee/activestorage-sftp"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 5.2.0"
  spec.add_dependency "net-sftp", ">= 2.1.2"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
end
