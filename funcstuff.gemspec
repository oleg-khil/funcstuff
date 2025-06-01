Gem::Specification.new do |s|
  s.name        = "funcstuff"
  s.version     = "0.0.1"
  s.summary     = "Small and minimalistic implementations of concepts found in functional languages"
  s.authors     = ["me"]
  s.files       = Dir['lib/**/*'] +
                    Dir['spec/**/*'] +
                      Dir['minitest/**/*'] +
                        Dir['**/*.adoc']
  s.homepage    = "https://github.com/oleg-khil/funcstuff"
  s.required_ruby_version = ">= 3.2"
  # s.license     = "NOT CHOSEN YET"
end
