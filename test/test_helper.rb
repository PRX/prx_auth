require "coveralls"
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "prx_auth"
require "rack/prx_auth"
require "pry"

require "minitest/autorun"
require "minitest/spec"
require "minitest/pride"
require "webmock/minitest"

TEST_CERT = "-----BEGIN CERTIFICATE-----\nMIIBGjCBwgIJALc+y9yEBugLMAoGCCqGSM49BAMCMBYxFDASBgNVBAMMC2lkLnBy\neC50ZXN0MB4XDTIyMDYwMzE0MjI0OVoXDTIzMDYwMzE0MjI0OVowFjEUMBIGA1UE\nAwwLaWQucHJ4LnRlc3QwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAQP8/BrEA/7\nHttUpOs0oxWNOtcUH2+0h2Oo/eXNyqs7CRScqmWWShKTzhiBlD8UNYZ3o4+kljl1\nazuLnv1Wxg7PMAoGCCqGSM49BAMCA0cAMEQCICXFwNxJQ9OLzyjN9EJnKQIP+2Jz\nfKWPJ1KyASkFDugyAiAxyfe3vR/XaSJOlJf8MjA5/0feEhiJcSszIrtHFweWLQ==\n-----END CERTIFICATE-----\n"
TEST_CERT_JSON = JSON.generate({certificates: {abcd1234: TEST_CERT}})
