DIST1=RehabMan-MaciASL
DIST2=RehabMan-patchmatic

.PHONY: all
all:
	xcodebuild -scheme MaciASL -configuration Debug
	xcodebuild -scheme MaciASL -configuration Release
	xcodebuild -scheme patchmatic -configuration Debug
	xcodebuild -scheme patchmatic -configuration Release

.PHONY: clean
clean:
	xcodebuild -scheme MaciASL -configuration Debug clean
	xcodebuild -scheme MaciASL -configuration Release clean
	xcodebuild -scheme patchmatic -configuration Debug clean
	xcodebuild -scheme patchmatic -configuration Release clean

.PHONY: install
install:
	cp -R Build/Products/Release/MaciASL.app /Applications
	cp Build/Products/Release/patchmatic /usr/bin

.PHONY: distribute
distribute:
	if [ -e ./Distribute ]; then rm -r ./Distribute; fi
	mkdir ./Distribute
	mkdir ./Distribute/MaciASL
	cp -R Build/Products/Release/MaciASL.app ./Distribute/MaciASL
	cp Build/Products/Release/patchmatic ./Distribute
	find ./Distribute -path *.DS_Store -delete
	find ./Distribute -path *.dSYM -exec echo rm -r {} \; >/tmp/org.maciasl.rm.dsym.sh
	chmod +x /tmp/org.maciasl.rm.dsym.sh
	/tmp/org.maciasl.rm.dsym.sh
	rm /tmp/org.maciasl.rm.dsym.sh
	ditto -c -k --sequesterRsrc --zlibCompressionLevel 9 ./Distribute/MaciASL ./Archive.zip
	mv ./Archive.zip ./Distribute/`date +$(DIST1)-%Y-%m%d.zip`
	ditto -c -k --sequesterRsrc --zlibCompressionLevel 9 ./Distribute/patchmatic ./Archive.zip
	mv ./Archive.zip ./Distribute/`date +$(DIST2)-%Y-%m%d.zip`
