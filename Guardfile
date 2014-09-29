guard :minitest, all_after_pass: true do
  watch(%r{^test/(.*)\/?test_(.*)\.rb})
  watch(%r{^lib/rack/(.*/)?([^/]+)\.rb})                      { |m| "test/#{m[1]}test_#{m[2]}.rb" }
  watch(%r{^test/test_helper\.rb})                       { 'test' }
  watch(%r{^test/factories/.+_factory\.rb})              { 'test' }
  watch(%r{^lib/rack/(.+)\.rb})                               { |m| "test/lib/#{m[1]}_test.rb" }
  watch(%r{^test/.+_test\.rb})
  watch(%r{^test/test_helper\.rb}) { 'test' }
end
