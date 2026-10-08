APP_NAME := MemoryPressureNotifier
APP := build/$(APP_NAME).app
INSTALLED_APP := $(HOME)/Applications/$(APP_NAME).app

# Sign with the first Apple Development certificate in the keychain, or ad-hoc if none is found.
# macOS may not allow notifications for an ad-hoc signed app.
SIGN_IDENTITY ?= $(or $(shell security find-identity -v -p codesigning | awk -F'"' '/Apple Development/ { print $$2; exit }'),-)

.PHONY: build install uninstall test-notification clean

build: $(APP)

$(APP): $(APP_NAME).swift Info.plist Makefile
	rm -rf $@
	mkdir -p $@/Contents/MacOS
	cp Info.plist $@/Contents/Info.plist
	swiftc -O -parse-as-library $(APP_NAME).swift -o $@/Contents/MacOS/$(APP_NAME)
	codesign --force --sign "$(SIGN_IDENTITY)" $@

# Put the app in ~/Applications and launch it. It registers itself as a login item on first launch.
install: build
	-pkill -x $(APP_NAME)
	rm -rf $(INSTALLED_APP)
	mkdir -p $(dir $(INSTALLED_APP))
	cp -R $(APP) $(INSTALLED_APP)
	open $(INSTALLED_APP)

uninstall:
	-$(INSTALLED_APP)/Contents/MacOS/$(APP_NAME) --unregister
	-pkill -x $(APP_NAME)
	rm -rf $(INSTALLED_APP)

# Relaunch the installed app and show a test notification
test-notification:
	-pkill -x $(APP_NAME)
	open $(INSTALLED_APP) --args --test-notification

clean:
	rm -rf build
