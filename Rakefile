# frozen_string_literal: true

$LOAD_PATH << File.realpath(".")

require "minitest"
require "minitest/hell"
require "minitest/test_task"

Minitest.load_plugins

Minitest::TestTask.create(:spec) do |t|
  t.libs << "lib"
  t.warning = false
  t.test_globs = ["spec/*_spec.rb"]
  t.test_prelude = [
    'require "lib/funcstuff"',
    'require "minitest"',
    'require "minitest/hell"'
  ]
  t.verbose = true
end

task default: :spec
