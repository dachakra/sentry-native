SENTRY_ORG=testorg-az
SENTRY_PROJECT=qt-04
VERSION ?= $(shell sentry-cli releases propose-version)
CMAKE=cmake

all: bin/example
.PHONY: all prereqs sentry-makefile sentry-makefile setup_release create_release associate_commits upload_debug_files run_crash run_message clean clean_db

bin/example: prereqs src/example.c
	$(CC) -g -o $@ -DSENTRY_RELEASE=\"$(VERSION)\" -Isentry-native/include src/example.c -Lbin -lsentry -Wl,-rpath,"@executable_path"

prereqs: bin/libsentry.dylib bin/crashpad_handler

bin/libsentry.dylib: sentry-makefile
	$(CMAKE) --build build --parallel --target sentry
	cp build/libsentry.dylib bin
	cp -R build/libsentry.dylib.dSYM bin

bin/crashpad_handler: sentry-makefile
	$(CMAKE) --build build --parallel --target crashpad_handler
	cp build/crashpad_build/handler/crashpad_handler bin
	cp -R build/crashpad_build/handler/crashpad_handler.dSYM bin

sentry-makefile: build/Makefile

build/Makefile:
	$(CMAKE) -B build -D SENTRY_INTEGRATION_QT=YES sentry-native


# SENTRYY
setup_release: create_release associate_commits
create_release:
	sentry-cli releases -o $(SENTRY_ORG) new -p $(SENTRY_PROJECT) $(VERSION)

associate_commits:
	sentry-cli releases -o $(SENTRY_ORG) -p $(SENTRY_PROJECT) set-commits $(VERSION) --auto

upload_debug_files:
	sentry-cli upload-dif --org testorg-az --project $(SENTRY_PROJECT) --wait --include-sources bin/

run_crash:
	SENTRY_DSN=https://10d87583a91d441a9ccae1eb7c5a8d6a@o87286.ingest.sentry.io/5838287 bin/example --crash

run_message:
	SENTRY_DSN=https://10d87583a91d441a9ccae1eb7c5a8d6a@o87286.ingest.sentry.io/5838287 bin/example --message

run_clean:
	SENTRY_DSN=https://10d87583a91d441a9ccae1eb7c5a8d6a@o87286.ingest.sentry.io/5838287 bin/example

clean:
	rm -rf ./bin/exampl*
	rm -rf ./bin/crash*
	rm -rf ./bin/libsent*
	rm -rf ./build
	rm -rf ./sentry-db
