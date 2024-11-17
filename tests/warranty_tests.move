#[test_only]
module warranty::warranty_tests;

const ENotImplemented: u64 = 0;

#[test, expected_failure(abort_code = ::warranty::warranty_tests::ENotImplemented)]
fun test_warranty_fail() {
    abort ENotImplemented
}
