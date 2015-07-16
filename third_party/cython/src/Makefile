PYTHON?=python
REPO = git://github.com/cython/cython.git

all:    local 

local:
	${PYTHON} setup.py build_ext --inplace

TMPDIR = .repo_tmp
.git: .gitrev
	rm -rf $(TMPDIR)
	git clone -n $(REPO) $(TMPDIR)
	cd $(TMPDIR) && git reset -q "$(shell cat .gitrev)"
	mv $(TMPDIR)/.git .
	rm -rf $(TMPDIR)
	git ls-files -d | xargs git checkout --

repo: .git


clean:
	@echo Cleaning Source
	@rm -fr build
	@rm -f *.py[co] */*.py[co] */*/*.py[co] */*/*/*.py[co]
	@rm -f *.so */*.so */*/*.so 
	@rm -f *.pyd */*.pyd */*/*.pyd 
	@rm -f *~ */*~ */*/*~
	@rm -f core */core
	@rm -f Cython/Compiler/*.c
	@rm -f Cython/Plex/*.c
	@rm -f Cython/Runtime/refnanny.c
	@(cd Demos; $(MAKE) clean)

testclean:
	rm -fr BUILD

test:	testclean
	${PYTHON} runtests.py -vv

s5:
	$(MAKE) -C Doc/s5 slides
