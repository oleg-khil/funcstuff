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
end

task default: :spec
