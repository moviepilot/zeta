# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'contractor/version'

Gem::Specification.new do |spec|
  spec.name          = 'contractor'
  spec.version       = Contractor::VERSION
  spec.authors       = ['Jannis Hermanns']
  spec.email         = ['jannis@gmail.com']

  spec.summary       = 'Collects and validates the publish/consume contracts of your infrastructure'
  spec.description   = 'Vlad'
  spec.homepage      = 'https://github.com/moviepilot/contractor'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://gems.moviepilot.com'
  end

  spec.add_runtime_dependency 'rake', '~> 10.2'
  spec.add_runtime_dependency 'minimum-term'

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry'
end
