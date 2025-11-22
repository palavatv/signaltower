#!/bin/sh
SIGNALTOWER_PORT="4235" mix test test/room_test.exs test/session_test.exs test/test_helper.exs
ok=$?

# prometheus_stats_test test counters incrementing, but I assume this conflicts with
# room_test and session_test as these also call stats functions in parallel.
# I think those test file runs share the module state which own the prometheus counters.
#
# To workaround this issue, we run conflicting test files not together.
mix test test/prometheus_stats_test.exs && $ok
