# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'domoz/version'

Gem::Specification.new do |spec|
  spec.name          = 'domoz'
  spec.version       = Domoz::VERSION
  spec.authors       = ['Stefan - Zipkid - Goethals']
  spec.email         = ['stefan@zipkid.eu']
  spec.summary       = 'Domotic by Zipkid'
  spec.description   = 'This program reads temperature from sensors via snmp,
  gets info from Google Calendar and with this info, controls a heating unit.
  It will also report the current temperatures to Google Calendar.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'simplecov'

  # spec.add_runtime_dependency 'slack-rtmapi'
end
