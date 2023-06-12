all: clean depends build bundle

clean:
	-rm -rf ../out

depends:
	cd ..; pub get; cd tool

build: test doc

test: depends
	@echo "********************************************************************************"
	@echo "RUNNING TESTS"
	@echo "********************************************************************************"

	dart ../test/all_tests_web.dart

doc: depends
	@echo "********************************************************************************"
	@echo "MAKING DOCUMENTATION"
	@echo "********************************************************************************"

	docgen  --start-page=pointycastle \
                --package-root=../packages \
                --compile \
                ../lib/pointycastle.dart

	-rm -rf ../out/doc
	mkdir -p ../out
	mv ./dartdoc-viewer/client/out/web ../out/doc
	rm -rf ./dartdoc-viewer

bundle: bundle-package bundle-doc

bundle-package: test
	@echo "********************************************************************************"
	@echo "MAKING PACKAGE BUNDLE"
	@echo "********************************************************************************"

	-rm ../out/bundle/pointycastle.tar.gz
	mkdir -p ../out/bundle

	tar -c -z -C .. --exclude packages -f ../out/bundle/pointycastle.tar.gz LICENSE README.md changelog.md pubspec.yaml benchmark/ lib/ licenses/ test/ tool/

bundle-doc: doc
	@echo "********************************************************************************"
	@echo "MAKING DOC BUNDLE"
	@echo "********************************************************************************"

	-rm ../out/bundle/pointycastle-doc.tar.gz
	mkdir -p ../out/bundle

	tar -c -z -C../out/doc -f ../out/bundle/pointycastle-doc.tar.gz .

deploy: deploy-doc deploy-pub

deploy-doc: doc
	@echo "********************************************************************************"
	@echo "DEPLOYING DOC TO GITHUB'S GH-PAGES"
	@echo "********************************************************************************"

deploy-pub: test
	@echo "********************************************************************************"
	@echo "DEPLOYING TO PUB"
	@echo "********************************************************************************"

