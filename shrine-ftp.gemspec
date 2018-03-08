Gem::Specification.new do |s|
  s.name        = 'shrine-ftp'
  s.version     = '0.1.0'
  s.date        = '2018-03-08'
  s.summary     = "Shrine storage via SFTP"
  s.description = "Shrine storage that uploads files to an SFTP server."
  s.authors     = ["Bit Zesty", "Louise Yang"]
  s.email       = 'info@bitzesty.com'
  s.files       = ["lib/shrine/storage/sftp.rb"]
  s.homepage    =
      'http://rubygems.org/gems/shrine-sftp'
  s.license       = 'MIT'
  s.add_runtime_dependency "net-sftp", [">= 2.1.2"]
end
