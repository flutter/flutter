# coding=utf-8
# (The line above is necessary so that I can use 世界 in the
# *comment* below without Python getting all bent out of shape.)

# Copyright 2007-2009 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

'''Mercurial interface to codereview.appspot.com.

To configure, set the following options in
your repository's .hg/hgrc file.

	[extensions]
	codereview = /path/to/codereview.py

	[codereview]
	server = codereview.appspot.com

The server should be running Rietveld; see http://code.google.com/p/rietveld/.

In addition to the new commands, this extension introduces
the file pattern syntax @nnnnnn, where nnnnnn is a change list
number, to mean the files included in that change list, which
must be associated with the current client.

For example, if change 123456 contains the files x.go and y.go,
"hg diff @123456" is equivalent to"hg diff x.go y.go".
'''

import sys

if __name__ == "__main__":
	print >>sys.stderr, "This is a Mercurial extension and should not be invoked directly."
	sys.exit(2)

# We require Python 2.6 for the json package.
if sys.version < '2.6':
	print >>sys.stderr, "The codereview extension requires Python 2.6 or newer."
	print >>sys.stderr, "You are running Python " + sys.version
	sys.exit(2)

import json
import os
import re
import stat
import subprocess
import threading
import time

from mercurial import commands as hg_commands
from mercurial import util as hg_util

defaultcc = None
codereview_disabled = None
real_rollback = None
releaseBranch = None
server = "codereview.appspot.com"
server_url_base = None

#######################################################################
# Normally I would split this into multiple files, but it simplifies
# import path headaches to keep it all in one file.  Sorry.
# The different parts of the file are separated by banners like this one.

#######################################################################
# Helpers

def RelativePath(path, cwd):
	n = len(cwd)
	if path.startswith(cwd) and path[n] == '/':
		return path[n+1:]
	return path

def Sub(l1, l2):
	return [l for l in l1 if l not in l2]

def Add(l1, l2):
	l = l1 + Sub(l2, l1)
	l.sort()
	return l

def Intersect(l1, l2):
	return [l for l in l1 if l in l2]

#######################################################################
# RE: UNICODE STRING HANDLING
#
# Python distinguishes between the str (string of bytes)
# and unicode (string of code points) types.  Most operations
# work on either one just fine, but some (like regexp matching)
# require unicode, and others (like write) require str.
#
# As befits the language, Python hides the distinction between
# unicode and str by converting between them silently, but
# *only* if all the bytes/code points involved are 7-bit ASCII.
# This means that if you're not careful, your program works
# fine on "hello, world" and fails on "hello, 世界".  And of course,
# the obvious way to be careful - use static types - is unavailable.
# So the only way is trial and error to find where to put explicit
# conversions.
#
# Because more functions do implicit conversion to str (string of bytes)
# than do implicit conversion to unicode (string of code points),
# the convention in this module is to represent all text as str,
# converting to unicode only when calling a unicode-only function
# and then converting back to str as soon as possible.

def typecheck(s, t):
	if type(s) != t:
		raise hg_util.Abort("type check failed: %s has type %s != %s" % (repr(s), type(s), t))

# If we have to pass unicode instead of str, ustr does that conversion clearly.
def ustr(s):
	typecheck(s, str)
	return s.decode("utf-8")

# Even with those, Mercurial still sometimes turns unicode into str
# and then tries to use it as ascii.  Change Mercurial's default.
def set_mercurial_encoding_to_utf8():
	from mercurial import encoding
	encoding.encoding = 'utf-8'

set_mercurial_encoding_to_utf8()

# Even with those we still run into problems.
# I tried to do things by the book but could not convince
# Mercurial to let me check in a change with UTF-8 in the
# CL description or author field, no matter how many conversions
# between str and unicode I inserted and despite changing the
# default encoding.  I'm tired of this game, so set the default
# encoding for all of Python to 'utf-8', not 'ascii'.
def default_to_utf8():
	import sys
	stdout, __stdout__ = sys.stdout, sys.__stdout__
	reload(sys)  # site.py deleted setdefaultencoding; get it back
	sys.stdout, sys.__stdout__ = stdout, __stdout__
	sys.setdefaultencoding('utf-8')

default_to_utf8()

#######################################################################
# Status printer for long-running commands

global_status = None

def set_status(s):
	# print >>sys.stderr, "\t", time.asctime(), s
	global global_status
	global_status = s

class StatusThread(threading.Thread):
	def __init__(self):
		threading.Thread.__init__(self)
	def run(self):
		# pause a reasonable amount of time before
		# starting to display status messages, so that
		# most hg commands won't ever see them.
		time.sleep(30)

		# now show status every 15 seconds
		while True:
			time.sleep(15 - time.time() % 15)
			s = global_status
			if s is None:
				continue
			if s == "":
				s = "(unknown status)"
			print >>sys.stderr, time.asctime(), s

def start_status_thread():
	t = StatusThread()
	t.setDaemon(True)  # allowed to exit if t is still running
	t.start()

#######################################################################
# Change list parsing.
#
# Change lists are stored in .hg/codereview/cl.nnnnnn
# where nnnnnn is the number assigned by the code review server.
# Most data about a change list is stored on the code review server
# too: the description, reviewer, and cc list are all stored there.
# The only thing in the cl.nnnnnn file is the list of relevant files.
# Also, the existence of the cl.nnnnnn file marks this repository
# as the one where the change list lives.

emptydiff = """Index: ~rietveld~placeholder~
===================================================================
diff --git a/~rietveld~placeholder~ b/~rietveld~placeholder~
new file mode 100644
"""

class CL(object):
	def __init__(self, name):
		typecheck(name, str)
		self.name = name
		self.desc = ''
		self.files = []
		self.reviewer = []
		self.cc = []
		self.url = ''
		self.local = False
		self.web = False
		self.copied_from = None	# None means current user
		self.mailed = False
		self.private = False
		self.lgtm = []

	def DiskText(self):
		cl = self
		s = ""
		if cl.copied_from:
			s += "Author: " + cl.copied_from + "\n\n"
		if cl.private:
			s += "Private: " + str(self.private) + "\n"
		s += "Mailed: " + str(self.mailed) + "\n"
		s += "Description:\n"
		s += Indent(cl.desc, "\t")
		s += "Files:\n"
		for f in cl.files:
			s += "\t" + f + "\n"
		typecheck(s, str)
		return s

	def EditorText(self):
		cl = self
		s = _change_prolog
		s += "\n"
		if cl.copied_from:
			s += "Author: " + cl.copied_from + "\n"
		if cl.url != '':
			s += 'URL: ' + cl.url + '	# cannot edit\n\n'
		if cl.private:
			s += "Private: True\n"
		s += "Reviewer: " + JoinComma(cl.reviewer) + "\n"
		s += "CC: " + JoinComma(cl.cc) + "\n"
		s += "\n"
		s += "Description:\n"
		if cl.desc == '':
			s += "\t<enter description here>\n"
		else:
			s += Indent(cl.desc, "\t")
		s += "\n"
		if cl.local or cl.name == "new":
			s += "Files:\n"
			for f in cl.files:
				s += "\t" + f + "\n"
			s += "\n"
		typecheck(s, str)
		return s

	def PendingText(self, quick=False):
		cl = self
		s = cl.name + ":" + "\n"
		s += Indent(cl.desc, "\t")
		s += "\n"
		if cl.copied_from:
			s += "\tAuthor: " + cl.copied_from + "\n"
		if not quick:
			s += "\tReviewer: " + JoinComma(cl.reviewer) + "\n"
			for (who, line) in cl.lgtm:
				s += "\t\t" + who + ": " + line + "\n"
			s += "\tCC: " + JoinComma(cl.cc) + "\n"
		s += "\tFiles:\n"
		for f in cl.files:
			s += "\t\t" + f + "\n"
		typecheck(s, str)
		return s

	def Flush(self, ui, repo):
		if self.name == "new":
			self.Upload(ui, repo, gofmt_just_warn=True, creating=True)
		dir = CodeReviewDir(ui, repo)
		path = dir + '/cl.' + self.name
		f = open(path+'!', "w")
		f.write(self.DiskText())
		f.close()
		if sys.platform == "win32" and os.path.isfile(path):
			os.remove(path)
		os.rename(path+'!', path)
		if self.web and not self.copied_from:
			EditDesc(self.name, desc=self.desc,
				reviewers=JoinComma(self.reviewer), cc=JoinComma(self.cc),
				private=self.private)

	def Delete(self, ui, repo):
		dir = CodeReviewDir(ui, repo)
		os.unlink(dir + "/cl." + self.name)

	def Subject(self):
		s = line1(self.desc)
		if len(s) > 60:
			s = s[0:55] + "..."
		if self.name != "new":
			s = "code review %s: %s" % (self.name, s)
		typecheck(s, str)
		return s

	def Upload(self, ui, repo, send_mail=False, gofmt=True, gofmt_just_warn=False, creating=False, quiet=False):
		if not self.files and not creating:
			ui.warn("no files in change list\n")
		if ui.configbool("codereview", "force_gofmt", True) and gofmt:
			CheckFormat(ui, repo, self.files, just_warn=gofmt_just_warn)
		set_status("uploading CL metadata + diffs")
		os.chdir(repo.root)
		form_fields = [
			("content_upload", "1"),
			("reviewers", JoinComma(self.reviewer)),
			("cc", JoinComma(self.cc)),
			("description", self.desc),
			("base_hashes", ""),
		]

		if self.name != "new":
			form_fields.append(("issue", self.name))
		vcs = None
		# We do not include files when creating the issue,
		# because we want the patch sets to record the repository
		# and base revision they are diffs against.  We use the patch
		# set message for that purpose, but there is no message with
		# the first patch set.  Instead the message gets used as the
		# new CL's overall subject.  So omit the diffs when creating
		# and then we'll run an immediate upload.
		# This has the effect that every CL begins with an empty "Patch set 1".
		if self.files and not creating:
			vcs = MercurialVCS(upload_options, ui, repo)
			data = vcs.GenerateDiff(self.files)
			files = vcs.GetBaseFiles(data)
			if len(data) > MAX_UPLOAD_SIZE:
				uploaded_diff_file = []
				form_fields.append(("separate_patches", "1"))
			else:
				uploaded_diff_file = [("data", "data.diff", data)]
		else:
			uploaded_diff_file = [("data", "data.diff", emptydiff)]
		
		if vcs and self.name != "new":
			form_fields.append(("subject", "diff -r " + vcs.base_rev + " " + ui.expandpath("default")))
		else:
			# First upload sets the subject for the CL itself.
			form_fields.append(("subject", self.Subject()))
		ctype, body = EncodeMultipartFormData(form_fields, uploaded_diff_file)
		response_body = MySend("/upload", body, content_type=ctype)
		patchset = None
		msg = response_body
		lines = msg.splitlines()
		if len(lines) >= 2:
			msg = lines[0]
			patchset = lines[1].strip()
			patches = [x.split(" ", 1) for x in lines[2:]]
		if response_body.startswith("Issue updated.") and quiet:
			pass
		else:
			ui.status(msg + "\n")
		set_status("uploaded CL metadata + diffs")
		if not response_body.startswith("Issue created.") and not response_body.startswith("Issue updated."):
			raise hg_util.Abort("failed to update issue: " + response_body)
		issue = msg[msg.rfind("/")+1:]
		self.name = issue
		if not self.url:
			self.url = server_url_base + self.name
		if not uploaded_diff_file:
			set_status("uploading patches")
			patches = UploadSeparatePatches(issue, rpc, patchset, data, upload_options)
		if vcs:
			set_status("uploading base files")
			vcs.UploadBaseFiles(issue, rpc, patches, patchset, upload_options, files)
		if send_mail:
			set_status("sending mail")
			MySend("/" + issue + "/mail", payload="")
		self.web = True
		set_status("flushing changes to disk")
		self.Flush(ui, repo)
		return

	def Mail(self, ui, repo):
		pmsg = "Hello " + JoinComma(self.reviewer)
		if self.cc:
			pmsg += " (cc: %s)" % (', '.join(self.cc),)
		pmsg += ",\n"
		pmsg += "\n"
		repourl = ui.expandpath("default")
		if not self.mailed:
			pmsg += "I'd like you to review this change to\n" + repourl + "\n"
		else:
			pmsg += "Please take another look.\n"
		typecheck(pmsg, str)
		PostMessage(ui, self.name, pmsg, subject=self.Subject())
		self.mailed = True
		self.Flush(ui, repo)

def GoodCLName(name):
	typecheck(name, str)
	return re.match("^[0-9]+$", name)

def ParseCL(text, name):
	typecheck(text, str)
	typecheck(name, str)
	sname = None
	lineno = 0
	sections = {
		'Author': '',
		'Description': '',
		'Files': '',
		'URL': '',
		'Reviewer': '',
		'CC': '',
		'Mailed': '',
		'Private': '',
	}
	for line in text.split('\n'):
		lineno += 1
		line = line.rstrip()
		if line != '' and line[0] == '#':
			continue
		if line == '' or line[0] == ' ' or line[0] == '\t':
			if sname == None and line != '':
				return None, lineno, 'text outside section'
			if sname != None:
				sections[sname] += line + '\n'
			continue
		p = line.find(':')
		if p >= 0:
			s, val = line[:p].strip(), line[p+1:].strip()
			if s in sections:
				sname = s
				if val != '':
					sections[sname] += val + '\n'
				continue
		return None, lineno, 'malformed section header'

	for k in sections:
		sections[k] = StripCommon(sections[k]).rstrip()

	cl = CL(name)
	if sections['Author']:
		cl.copied_from = sections['Author']
	cl.desc = sections['Description']
	for line in sections['Files'].split('\n'):
		i = line.find('#')
		if i >= 0:
			line = line[0:i].rstrip()
		line = line.strip()
		if line == '':
			continue
		cl.files.append(line)
	cl.reviewer = SplitCommaSpace(sections['Reviewer'])
	cl.cc = SplitCommaSpace(sections['CC'])
	cl.url = sections['URL']
	if sections['Mailed'] != 'False':
		# Odd default, but avoids spurious mailings when
		# reading old CLs that do not have a Mailed: line.
		# CLs created with this update will always have 
		# Mailed: False on disk.
		cl.mailed = True
	if sections['Private'] in ('True', 'true', 'Yes', 'yes'):
		cl.private = True
	if cl.desc == '<enter description here>':
		cl.desc = ''
	return cl, 0, ''

def SplitCommaSpace(s):
	typecheck(s, str)
	s = s.strip()
	if s == "":
		return []
	return re.split(", *", s)

def CutDomain(s):
	typecheck(s, str)
	i = s.find('@')
	if i >= 0:
		s = s[0:i]
	return s

def JoinComma(l):
	for s in l:
		typecheck(s, str)
	return ", ".join(l)

def ExceptionDetail():
	s = str(sys.exc_info()[0])
	if s.startswith("<type '") and s.endswith("'>"):
		s = s[7:-2]
	elif s.startswith("<class '") and s.endswith("'>"):
		s = s[8:-2]
	arg = str(sys.exc_info()[1])
	if len(arg) > 0:
		s += ": " + arg
	return s

def IsLocalCL(ui, repo, name):
	return GoodCLName(name) and os.access(CodeReviewDir(ui, repo) + "/cl." + name, 0)

# Load CL from disk and/or the web.
def LoadCL(ui, repo, name, web=True):
	typecheck(name, str)
	set_status("loading CL " + name)
	if not GoodCLName(name):
		return None, "invalid CL name"
	dir = CodeReviewDir(ui, repo)
	path = dir + "cl." + name
	if os.access(path, 0):
		ff = open(path)
		text = ff.read()
		ff.close()
		cl, lineno, err = ParseCL(text, name)
		if err != "":
			return None, "malformed CL data: "+err
		cl.local = True
	else:
		cl = CL(name)
	if web:
		set_status("getting issue metadata from web")
		d = JSONGet(ui, "/api/" + name + "?messages=true")
		set_status(None)
		if d is None:
			return None, "cannot load CL %s from server" % (name,)
		if 'owner_email' not in d or 'issue' not in d or str(d['issue']) != name:
			return None, "malformed response loading CL data from code review server"
		cl.dict = d
		cl.reviewer = d.get('reviewers', [])
		cl.cc = d.get('cc', [])
		if cl.local and cl.copied_from and cl.desc:
			# local copy of CL written by someone else
			# and we saved a description.  use that one,
			# so that committers can edit the description
			# before doing hg submit.
			pass
		else:
			cl.desc = d.get('description', "")
		cl.url = server_url_base + name
		cl.web = True
		cl.private = d.get('private', False) != False
		cl.lgtm = []
		for m in d.get('messages', []):
			if m.get('approval', False) == True:
				who = re.sub('@.*', '', m.get('sender', ''))
				text = re.sub("\n(.|\n)*", '', m.get('text', ''))
				cl.lgtm.append((who, text))

	set_status("loaded CL " + name)
	return cl, ''

class LoadCLThread(threading.Thread):
	def __init__(self, ui, repo, dir, f, web):
		threading.Thread.__init__(self)
		self.ui = ui
		self.repo = repo
		self.dir = dir
		self.f = f
		self.web = web
		self.cl = None
	def run(self):
		cl, err = LoadCL(self.ui, self.repo, self.f[3:], web=self.web)
		if err != '':
			self.ui.warn("loading "+self.dir+self.f+": " + err + "\n")
			return
		self.cl = cl

# Load all the CLs from this repository.
def LoadAllCL(ui, repo, web=True):
	dir = CodeReviewDir(ui, repo)
	m = {}
	files = [f for f in os.listdir(dir) if f.startswith('cl.')]
	if not files:
		return m
	active = []
	first = True
	for f in files:
		t = LoadCLThread(ui, repo, dir, f, web)
		t.start()
		if web and first:
			# first request: wait in case it needs to authenticate
			# otherwise we get lots of user/password prompts
			# running in parallel.
			t.join()
			if t.cl:
				m[t.cl.name] = t.cl
			first = False
		else:
			active.append(t)
	for t in active:
		t.join()
		if t.cl:
			m[t.cl.name] = t.cl
	return m

# Find repository root.  On error, ui.warn and return None
def RepoDir(ui, repo):
	url = repo.url();
	if not url.startswith('file:'):
		ui.warn("repository %s is not in local file system\n" % (url,))
		return None
	url = url[5:]
	if url.endswith('/'):
		url = url[:-1]
	typecheck(url, str)
	return url

# Find (or make) code review directory.  On error, ui.warn and return None
def CodeReviewDir(ui, repo):
	dir = RepoDir(ui, repo)
	if dir == None:
		return None
	dir += '/.hg/codereview/'
	if not os.path.isdir(dir):
		try:
			os.mkdir(dir, 0700)
		except:
			ui.warn('cannot mkdir %s: %s\n' % (dir, ExceptionDetail()))
			return None
	typecheck(dir, str)
	return dir

# Turn leading tabs into spaces, so that the common white space
# prefix doesn't get confused when people's editors write out 
# some lines with spaces, some with tabs.  Only a heuristic
# (some editors don't use 8 spaces either) but a useful one.
def TabsToSpaces(line):
	i = 0
	while i < len(line) and line[i] == '\t':
		i += 1
	return ' '*(8*i) + line[i:]

# Strip maximal common leading white space prefix from text
def StripCommon(text):
	typecheck(text, str)
	ws = None
	for line in text.split('\n'):
		line = line.rstrip()
		if line == '':
			continue
		line = TabsToSpaces(line)
		white = line[:len(line)-len(line.lstrip())]
		if ws == None:
			ws = white
		else:
			common = ''
			for i in range(min(len(white), len(ws))+1):
				if white[0:i] == ws[0:i]:
					common = white[0:i]
			ws = common
		if ws == '':
			break
	if ws == None:
		return text
	t = ''
	for line in text.split('\n'):
		line = line.rstrip()
		line = TabsToSpaces(line)
		if line.startswith(ws):
			line = line[len(ws):]
		if line == '' and t == '':
			continue
		t += line + '\n'
	while len(t) >= 2 and t[-2:] == '\n\n':
		t = t[:-1]
	typecheck(t, str)
	return t

# Indent text with indent.
def Indent(text, indent):
	typecheck(text, str)
	typecheck(indent, str)
	t = ''
	for line in text.split('\n'):
		t += indent + line + '\n'
	typecheck(t, str)
	return t

# Return the first line of l
def line1(text):
	typecheck(text, str)
	return text.split('\n')[0]

_change_prolog = """# Change list.
# Lines beginning with # are ignored.
# Multi-line values should be indented.
"""

desc_re = '^(.+: |(tag )?(release|weekly)\.|fix build|undo CL)'

desc_msg = '''Your CL description appears not to use the standard form.

The first line of your change description is conventionally a
one-line summary of the change, prefixed by the primary affected package,
and is used as the subject for code review mail; the rest of the description
elaborates.

Examples:

	encoding/rot13: new package

	math: add IsInf, IsNaN
	
	net: fix cname in LookupHost

	unicode: update to Unicode 5.0.2

'''

def promptyesno(ui, msg):
	if hgversion >= "2.7":
		return ui.promptchoice(msg + " $$ &yes $$ &no", 0) == 0
	else:
		return ui.promptchoice(msg, ["&yes", "&no"], 0) == 0

def promptremove(ui, repo, f):
	if promptyesno(ui, "hg remove %s (y/n)?" % (f,)):
		if hg_commands.remove(ui, repo, 'path:'+f) != 0:
			ui.warn("error removing %s" % (f,))

def promptadd(ui, repo, f):
	if promptyesno(ui, "hg add %s (y/n)?" % (f,)):
		if hg_commands.add(ui, repo, 'path:'+f) != 0:
			ui.warn("error adding %s" % (f,))

def EditCL(ui, repo, cl):
	set_status(None)	# do not show status
	s = cl.EditorText()
	while True:
		s = ui.edit(s, ui.username())
		
		# We can't trust Mercurial + Python not to die before making the change,
		# so, by popular demand, just scribble the most recent CL edit into
		# $(hg root)/last-change so that if Mercurial does die, people
		# can look there for their work.
		try:
			f = open(repo.root+"/last-change", "w")
			f.write(s)
			f.close()
		except:
			pass

		clx, line, err = ParseCL(s, cl.name)
		if err != '':
			if not promptyesno(ui, "error parsing change list: line %d: %s\nre-edit (y/n)?" % (line, err)):
				return "change list not modified"
			continue
		
		# Check description.
		if clx.desc == '':
			if promptyesno(ui, "change list should have a description\nre-edit (y/n)?"):
				continue
		elif re.search('<enter reason for undo>', clx.desc):
			if promptyesno(ui, "change list description omits reason for undo\nre-edit (y/n)?"):
				continue
		elif not re.match(desc_re, clx.desc.split('\n')[0]):
			if promptyesno(ui, desc_msg + "re-edit (y/n)?"):
				continue

		# Check file list for files that need to be hg added or hg removed
		# or simply aren't understood.
		pats = ['path:'+f for f in clx.files]
		changed = hg_matchPattern(ui, repo, *pats, modified=True, added=True, removed=True)
		deleted = hg_matchPattern(ui, repo, *pats, deleted=True)
		unknown = hg_matchPattern(ui, repo, *pats, unknown=True)
		ignored = hg_matchPattern(ui, repo, *pats, ignored=True)
		clean = hg_matchPattern(ui, repo, *pats, clean=True)
		files = []
		for f in clx.files:
			if f in changed:
				files.append(f)
				continue
			if f in deleted:
				promptremove(ui, repo, f)
				files.append(f)
				continue
			if f in unknown:
				promptadd(ui, repo, f)
				files.append(f)
				continue
			if f in ignored:
				ui.warn("error: %s is excluded by .hgignore; omitting\n" % (f,))
				continue
			if f in clean:
				ui.warn("warning: %s is listed in the CL but unchanged\n" % (f,))
				files.append(f)
				continue
			p = repo.root + '/' + f
			if os.path.isfile(p):
				ui.warn("warning: %s is a file but not known to hg\n" % (f,))
				files.append(f)
				continue
			if os.path.isdir(p):
				ui.warn("error: %s is a directory, not a file; omitting\n" % (f,))
				continue
			ui.warn("error: %s does not exist; omitting\n" % (f,))
		clx.files = files

		cl.desc = clx.desc
		cl.reviewer = clx.reviewer
		cl.cc = clx.cc
		cl.files = clx.files
		cl.private = clx.private
		break
	return ""

# For use by submit, etc. (NOT by change)
# Get change list number or list of files from command line.
# If files are given, make a new change list.
def CommandLineCL(ui, repo, pats, opts, defaultcc=None):
	if len(pats) > 0 and GoodCLName(pats[0]):
		if len(pats) != 1:
			return None, "cannot specify change number and file names"
		if opts.get('message'):
			return None, "cannot use -m with existing CL"
		cl, err = LoadCL(ui, repo, pats[0], web=True)
		if err != "":
			return None, err
	else:
		cl = CL("new")
		cl.local = True
		cl.files = ChangedFiles(ui, repo, pats, taken=Taken(ui, repo))
		if not cl.files:
			return None, "no files changed"
	if opts.get('reviewer'):
		cl.reviewer = Add(cl.reviewer, SplitCommaSpace(opts.get('reviewer')))
	if opts.get('cc'):
		cl.cc = Add(cl.cc, SplitCommaSpace(opts.get('cc')))
	if defaultcc:
		cl.cc = Add(cl.cc, defaultcc)
	if cl.name == "new":
		if opts.get('message'):
			cl.desc = opts.get('message')
		else:
			err = EditCL(ui, repo, cl)
			if err != '':
				return None, err
	return cl, ""

#######################################################################
# Change list file management

# Return list of changed files in repository that match pats.
# The patterns came from the command line, so we warn
# if they have no effect or cannot be understood.
def ChangedFiles(ui, repo, pats, taken=None):
	taken = taken or {}
	# Run each pattern separately so that we can warn about
	# patterns that didn't do anything useful.
	for p in pats:
		for f in hg_matchPattern(ui, repo, p, unknown=True):
			promptadd(ui, repo, f)
		for f in hg_matchPattern(ui, repo, p, removed=True):
			promptremove(ui, repo, f)
		files = hg_matchPattern(ui, repo, p, modified=True, added=True, removed=True)
		for f in files:
			if f in taken:
				ui.warn("warning: %s already in CL %s\n" % (f, taken[f].name))
		if not files:
			ui.warn("warning: %s did not match any modified files\n" % (p,))

	# Again, all at once (eliminates duplicates)
	l = hg_matchPattern(ui, repo, *pats, modified=True, added=True, removed=True)
	l.sort()
	if taken:
		l = Sub(l, taken.keys())
	return l

# Return list of changed files in repository that match pats and still exist.
def ChangedExistingFiles(ui, repo, pats, opts):
	l = hg_matchPattern(ui, repo, *pats, modified=True, added=True)
	l.sort()
	return l

# Return list of files claimed by existing CLs
def Taken(ui, repo):
	all = LoadAllCL(ui, repo, web=False)
	taken = {}
	for _, cl in all.items():
		for f in cl.files:
			taken[f] = cl
	return taken

# Return list of changed files that are not claimed by other CLs
def DefaultFiles(ui, repo, pats):
	return ChangedFiles(ui, repo, pats, taken=Taken(ui, repo))

#######################################################################
# File format checking.

def CheckFormat(ui, repo, files, just_warn=False):
	set_status("running gofmt")
	CheckGofmt(ui, repo, files, just_warn)
	CheckTabfmt(ui, repo, files, just_warn)

# Check that gofmt run on the list of files does not change them
def CheckGofmt(ui, repo, files, just_warn):
	files = gofmt_required(files)
	if not files:
		return
	cwd = os.getcwd()
	files = [RelativePath(repo.root + '/' + f, cwd) for f in files]
	files = [f for f in files if os.access(f, 0)]
	if not files:
		return
	try:
		cmd = subprocess.Popen(["gofmt", "-l"] + files, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=sys.platform != "win32")
		cmd.stdin.close()
	except:
		raise hg_util.Abort("gofmt: " + ExceptionDetail())
	data = cmd.stdout.read()
	errors = cmd.stderr.read()
	cmd.wait()
	set_status("done with gofmt")
	if len(errors) > 0:
		ui.warn("gofmt errors:\n" + errors.rstrip() + "\n")
		return
	if len(data) > 0:
		msg = "gofmt needs to format these files (run hg gofmt):\n" + Indent(data, "\t").rstrip()
		if just_warn:
			ui.warn("warning: " + msg + "\n")
		else:
			raise hg_util.Abort(msg)
	return

# Check that *.[chys] files indent using tabs.
def CheckTabfmt(ui, repo, files, just_warn):
	files = [f for f in files if f.startswith('src/') and re.search(r"\.[chys]$", f) and not re.search(r"\.tab\.[ch]$", f)]
	if not files:
		return
	cwd = os.getcwd()
	files = [RelativePath(repo.root + '/' + f, cwd) for f in files]
	files = [f for f in files if os.access(f, 0)]
	badfiles = []
	for f in files:
		try:
			for line in open(f, 'r'):
				# Four leading spaces is enough to complain about,
				# except that some Plan 9 code uses four spaces as the label indent,
				# so allow that.
				if line.startswith('    ') and not re.match('    [A-Za-z0-9_]+:', line):
					badfiles.append(f)
					break
		except:
			# ignore cannot open file, etc.
			pass
	if len(badfiles) > 0:
		msg = "these files use spaces for indentation (use tabs instead):\n\t" + "\n\t".join(badfiles)
		if just_warn:
			ui.warn("warning: " + msg + "\n")
		else:
			raise hg_util.Abort(msg)
	return

#######################################################################
# CONTRIBUTORS file parsing

contributorsCache = None
contributorsURL = None

def ReadContributors(ui, repo):
	global contributorsCache
	if contributorsCache is not None:
		return contributorsCache

	try:
		if contributorsURL is not None:
			opening = contributorsURL
			f = urllib2.urlopen(contributorsURL)
		else:
			opening = repo.root + '/CONTRIBUTORS'
			f = open(repo.root + '/CONTRIBUTORS', 'r')
	except:
		ui.write("warning: cannot open %s: %s\n" % (opening, ExceptionDetail()))
		return

	contributors = {}
	for line in f:
		# CONTRIBUTORS is a list of lines like:
		#	Person <email>
		#	Person <email> <alt-email>
		# The first email address is the one used in commit logs.
		if line.startswith('#'):
			continue
		m = re.match(r"([^<>]+\S)\s+(<[^<>\s]+>)((\s+<[^<>\s]+>)*)\s*$", line)
		if m:
			name = m.group(1)
			email = m.group(2)[1:-1]
			contributors[email.lower()] = (name, email)
			for extra in m.group(3).split():
				contributors[extra[1:-1].lower()] = (name, email)

	contributorsCache = contributors
	return contributors

def CheckContributor(ui, repo, user=None):
	set_status("checking CONTRIBUTORS file")
	user, userline = FindContributor(ui, repo, user, warn=False)
	if not userline:
		raise hg_util.Abort("cannot find %s in CONTRIBUTORS" % (user,))
	return userline

def FindContributor(ui, repo, user=None, warn=True):
	if not user:
		user = ui.config("ui", "username")
		if not user:
			raise hg_util.Abort("[ui] username is not configured in .hgrc")
	user = user.lower()
	m = re.match(r".*<(.*)>", user)
	if m:
		user = m.group(1)

	contributors = ReadContributors(ui, repo)
	if user not in contributors:
		if warn:
			ui.warn("warning: cannot find %s in CONTRIBUTORS\n" % (user,))
		return user, None
	
	user, email = contributors[user]
	return email, "%s <%s>" % (user, email)

#######################################################################
# Mercurial helper functions.
# Read http://mercurial.selenic.com/wiki/MercurialApi before writing any of these.
# We use the ui.pushbuffer/ui.popbuffer + hg_commands.xxx tricks for all interaction
# with Mercurial.  It has proved the most stable as they make changes.

hgversion = hg_util.version()

# We require Mercurial 1.9 and suggest Mercurial 2.0.
# The details of the scmutil package changed then,
# so allowing earlier versions would require extra band-aids below.
# Ubuntu 11.10 ships with Mercurial 1.9.1 as the default version.
hg_required = "1.9"
hg_suggested = "2.0"

old_message = """

The code review extension requires Mercurial """+hg_required+""" or newer.
You are using Mercurial """+hgversion+""".

To install a new Mercurial, use

	sudo easy_install mercurial=="""+hg_suggested+"""

or visit http://mercurial.selenic.com/downloads/.
"""

linux_message = """
You may need to clear your current Mercurial installation by running:

	sudo apt-get remove mercurial mercurial-common
	sudo rm -rf /etc/mercurial
"""

if hgversion < hg_required:
	msg = old_message
	if os.access("/etc/mercurial", 0):
		msg += linux_message
	raise hg_util.Abort(msg)

from mercurial.hg import clean as hg_clean
from mercurial import cmdutil as hg_cmdutil
from mercurial import error as hg_error
from mercurial import match as hg_match
from mercurial import node as hg_node

class uiwrap(object):
	def __init__(self, ui):
		self.ui = ui
		ui.pushbuffer()
		self.oldQuiet = ui.quiet
		ui.quiet = True
		self.oldVerbose = ui.verbose
		ui.verbose = False
	def output(self):
		ui = self.ui
		ui.quiet = self.oldQuiet
		ui.verbose = self.oldVerbose
		return ui.popbuffer()

def to_slash(path):
	if sys.platform == "win32":
		return path.replace('\\', '/')
	return path

def hg_matchPattern(ui, repo, *pats, **opts):
	w = uiwrap(ui)
	hg_commands.status(ui, repo, *pats, **opts)
	text = w.output()
	ret = []
	prefix = to_slash(os.path.realpath(repo.root))+'/'
	for line in text.split('\n'):
		f = line.split()
		if len(f) > 1:
			if len(pats) > 0:
				# Given patterns, Mercurial shows relative to cwd
				p = to_slash(os.path.realpath(f[1]))
				if not p.startswith(prefix):
					print >>sys.stderr, "File %s not in repo root %s.\n" % (p, prefix)
				else:
					ret.append(p[len(prefix):])
			else:
				# Without patterns, Mercurial shows relative to root (what we want)
				ret.append(to_slash(f[1]))
	return ret

def hg_heads(ui, repo):
	w = uiwrap(ui)
	hg_commands.heads(ui, repo)
	return w.output()

noise = [
	"",
	"resolving manifests",
	"searching for changes",
	"couldn't find merge tool hgmerge",
	"adding changesets",
	"adding manifests",
	"adding file changes",
	"all local heads known remotely",
]

def isNoise(line):
	line = str(line)
	for x in noise:
		if line == x:
			return True
	return False

def hg_incoming(ui, repo):
	w = uiwrap(ui)
	ret = hg_commands.incoming(ui, repo, force=False, bundle="")
	if ret and ret != 1:
		raise hg_util.Abort(ret)
	return w.output()

def hg_log(ui, repo, **opts):
	for k in ['date', 'keyword', 'rev', 'user']:
		if not opts.has_key(k):
			opts[k] = ""
	w = uiwrap(ui)
	ret = hg_commands.log(ui, repo, **opts)
	if ret:
		raise hg_util.Abort(ret)
	return w.output()

def hg_outgoing(ui, repo, **opts):
	w = uiwrap(ui)
	ret = hg_commands.outgoing(ui, repo, **opts)
	if ret and ret != 1:
		raise hg_util.Abort(ret)
	return w.output()

def hg_pull(ui, repo, **opts):
	w = uiwrap(ui)
	ui.quiet = False
	ui.verbose = True  # for file list
	err = hg_commands.pull(ui, repo, **opts)
	for line in w.output().split('\n'):
		if isNoise(line):
			continue
		if line.startswith('moving '):
			line = 'mv ' + line[len('moving '):]
		if line.startswith('getting ') and line.find(' to ') >= 0:
			line = 'mv ' + line[len('getting '):]
		if line.startswith('getting '):
			line = '+ ' + line[len('getting '):]
		if line.startswith('removing '):
			line = '- ' + line[len('removing '):]
		ui.write(line + '\n')
	return err

def hg_push(ui, repo, **opts):
	w = uiwrap(ui)
	ui.quiet = False
	ui.verbose = True
	err = hg_commands.push(ui, repo, **opts)
	for line in w.output().split('\n'):
		if not isNoise(line):
			ui.write(line + '\n')
	return err

def hg_commit(ui, repo, *pats, **opts):
	return hg_commands.commit(ui, repo, *pats, **opts)

#######################################################################
# Mercurial precommit hook to disable commit except through this interface.

commit_okay = False

def precommithook(ui, repo, **opts):
	if commit_okay:
		return False  # False means okay.
	ui.write("\ncodereview extension enabled; use mail, upload, or submit instead of commit\n\n")
	return True

#######################################################################
# @clnumber file pattern support

# We replace scmutil.match with the MatchAt wrapper to add the @clnumber pattern.

match_repo = None
match_ui = None
match_orig = None

def InstallMatch(ui, repo):
	global match_repo
	global match_ui
	global match_orig

	match_ui = ui
	match_repo = repo

	from mercurial import scmutil
	match_orig = scmutil.match
	scmutil.match = MatchAt

def MatchAt(ctx, pats=None, opts=None, globbed=False, default='relpath'):
	taken = []
	files = []
	pats = pats or []
	opts = opts or {}
	
	for p in pats:
		if p.startswith('@'):
			taken.append(p)
			clname = p[1:]
			if clname == "default":
				files = DefaultFiles(match_ui, match_repo, [])
			else:
				if not GoodCLName(clname):
					raise hg_util.Abort("invalid CL name " + clname)
				cl, err = LoadCL(match_repo.ui, match_repo, clname, web=False)
				if err != '':
					raise hg_util.Abort("loading CL " + clname + ": " + err)
				if not cl.files:
					raise hg_util.Abort("no files in CL " + clname)
				files = Add(files, cl.files)
	pats = Sub(pats, taken) + ['path:'+f for f in files]

	# work-around for http://selenic.com/hg/rev/785bbc8634f8
	if not hasattr(ctx, 'match'):
		ctx = ctx[None]
	return match_orig(ctx, pats=pats, opts=opts, globbed=globbed, default=default)

#######################################################################
# Commands added by code review extension.

# As of Mercurial 2.1 the commands are all required to return integer
# exit codes, whereas earlier versions allowed returning arbitrary strings
# to be printed as errors.  We wrap the old functions to make sure we
# always return integer exit codes now.  Otherwise Mercurial dies
# with a TypeError traceback (unsupported operand type(s) for &: 'str' and 'int').
# Introduce a Python decorator to convert old functions to the new
# stricter convention.

def hgcommand(f):
	def wrapped(ui, repo, *pats, **opts):
		err = f(ui, repo, *pats, **opts)
		if type(err) is int:
			return err
		if not err:
			return 0
		raise hg_util.Abort(err)
	wrapped.__doc__ = f.__doc__
	return wrapped

#######################################################################
# hg change

@hgcommand
def change(ui, repo, *pats, **opts):
	"""create, edit or delete a change list

	Create, edit or delete a change list.
	A change list is a group of files to be reviewed and submitted together,
	plus a textual description of the change.
	Change lists are referred to by simple alphanumeric names.

	Changes must be reviewed before they can be submitted.

	In the absence of options, the change command opens the
	change list for editing in the default editor.

	Deleting a change with the -d or -D flag does not affect
	the contents of the files listed in that change.  To revert
	the files listed in a change, use

		hg revert @123456

	before running hg change -d 123456.
	"""

	if codereview_disabled:
		return codereview_disabled
	
	dirty = {}
	if len(pats) > 0 and GoodCLName(pats[0]):
		name = pats[0]
		if len(pats) != 1:
			return "cannot specify CL name and file patterns"
		pats = pats[1:]
		cl, err = LoadCL(ui, repo, name, web=True)
		if err != '':
			return err
		if not cl.local and (opts["stdin"] or not opts["stdout"]):
			return "cannot change non-local CL " + name
	else:
		name = "new"
		cl = CL("new")
		if repo[None].branch() != "default":
			return "cannot create CL outside default branch; switch with 'hg update default'"
		dirty[cl] = True
		files = ChangedFiles(ui, repo, pats, taken=Taken(ui, repo))

	if opts["delete"] or opts["deletelocal"]:
		if opts["delete"] and opts["deletelocal"]:
			return "cannot use -d and -D together"
		flag = "-d"
		if opts["deletelocal"]:
			flag = "-D"
		if name == "new":
			return "cannot use "+flag+" with file patterns"
		if opts["stdin"] or opts["stdout"]:
			return "cannot use "+flag+" with -i or -o"
		if not cl.local:
			return "cannot change non-local CL " + name
		if opts["delete"]:
			if cl.copied_from:
				return "original author must delete CL; hg change -D will remove locally"
			PostMessage(ui, cl.name, "*** Abandoned ***", send_mail=cl.mailed)
			EditDesc(cl.name, closed=True, private=cl.private)
		cl.Delete(ui, repo)
		return

	if opts["stdin"]:
		s = sys.stdin.read()
		clx, line, err = ParseCL(s, name)
		if err != '':
			return "error parsing change list: line %d: %s" % (line, err)
		if clx.desc is not None:
			cl.desc = clx.desc;
			dirty[cl] = True
		if clx.reviewer is not None:
			cl.reviewer = clx.reviewer
			dirty[cl] = True
		if clx.cc is not None:
			cl.cc = clx.cc
			dirty[cl] = True
		if clx.files is not None:
			cl.files = clx.files
			dirty[cl] = True
		if clx.private != cl.private:
			cl.private = clx.private
			dirty[cl] = True

	if not opts["stdin"] and not opts["stdout"]:
		if name == "new":
			cl.files = files
		err = EditCL(ui, repo, cl)
		if err != "":
			return err
		dirty[cl] = True

	for d, _ in dirty.items():
		name = d.name
		d.Flush(ui, repo)
		if name == "new":
			d.Upload(ui, repo, quiet=True)

	if opts["stdout"]:
		ui.write(cl.EditorText())
	elif opts["pending"]:
		ui.write(cl.PendingText())
	elif name == "new":
		if ui.quiet:
			ui.write(cl.name)
		else:
			ui.write("CL created: " + cl.url + "\n")
	return

#######################################################################
# hg code-login (broken?)

@hgcommand
def code_login(ui, repo, **opts):
	"""log in to code review server

	Logs in to the code review server, saving a cookie in
	a file in your home directory.
	"""
	if codereview_disabled:
		return codereview_disabled

	MySend(None)

#######################################################################
# hg clpatch / undo / release-apply / download
# All concerned with applying or unapplying patches to the repository.

@hgcommand
def clpatch(ui, repo, clname, **opts):
	"""import a patch from the code review server

	Imports a patch from the code review server into the local client.
	If the local client has already modified any of the files that the
	patch modifies, this command will refuse to apply the patch.

	Submitting an imported patch will keep the original author's
	name as the Author: line but add your own name to a Committer: line.
	"""
	if repo[None].branch() != "default":
		return "cannot run hg clpatch outside default branch"
	return clpatch_or_undo(ui, repo, clname, opts, mode="clpatch")

@hgcommand
def undo(ui, repo, clname, **opts):
	"""undo the effect of a CL
	
	Creates a new CL that undoes an earlier CL.
	After creating the CL, opens the CL text for editing so that
	you can add the reason for the undo to the description.
	"""
	if repo[None].branch() != "default":
		return "cannot run hg undo outside default branch"
	return clpatch_or_undo(ui, repo, clname, opts, mode="undo")

@hgcommand
def release_apply(ui, repo, clname, **opts):
	"""apply a CL to the release branch

	Creates a new CL copying a previously committed change
	from the main branch to the release branch.
	The current client must either be clean or already be in
	the release branch.
	
	The release branch must be created by starting with a
	clean client, disabling the code review plugin, and running:
	
		hg update weekly.YYYY-MM-DD
		hg branch release-branch.rNN
		hg commit -m 'create release-branch.rNN'
		hg push --new-branch
	
	Then re-enable the code review plugin.
	
	People can test the release branch by running
	
		hg update release-branch.rNN
	
	in a clean client.  To return to the normal tree,
	
		hg update default
	
	Move changes since the weekly into the release branch 
	using hg release-apply followed by the usual code review
	process and hg submit.

	When it comes time to tag the release, record the
	final long-form tag of the release-branch.rNN
	in the *default* branch's .hgtags file.  That is, run
	
		hg update default
	
	and then edit .hgtags as you would for a weekly.
		
	"""
	c = repo[None]
	if not releaseBranch:
		return "no active release branches"
	if c.branch() != releaseBranch:
		if c.modified() or c.added() or c.removed():
			raise hg_util.Abort("uncommitted local changes - cannot switch branches")
		err = hg_clean(repo, releaseBranch)
		if err:
			return err
	try:
		err = clpatch_or_undo(ui, repo, clname, opts, mode="backport")
		if err:
			raise hg_util.Abort(err)
	except Exception, e:
		hg_clean(repo, "default")
		raise e
	return None

def rev2clname(rev):
	# Extract CL name from revision description.
	# The last line in the description that is a codereview URL is the real one.
	# Earlier lines might be part of the user-written description.
	all = re.findall('(?m)^http://codereview.appspot.com/([0-9]+)$', rev.description())
	if len(all) > 0:
		return all[-1]
	return ""

undoHeader = """undo CL %s / %s

<enter reason for undo>

««« original CL description
"""

undoFooter = """
»»»
"""

backportHeader = """[%s] %s

««« CL %s / %s
"""

backportFooter = """
»»»
"""

# Implementation of clpatch/undo.
def clpatch_or_undo(ui, repo, clname, opts, mode):
	if codereview_disabled:
		return codereview_disabled

	if mode == "undo" or mode == "backport":
		# Find revision in Mercurial repository.
		# Assume CL number is 7+ decimal digits.
		# Otherwise is either change log sequence number (fewer decimal digits),
		# hexadecimal hash, or tag name.
		# Mercurial will fall over long before the change log
		# sequence numbers get to be 7 digits long.
		if re.match('^[0-9]{7,}$', clname):
			found = False
			for r in hg_log(ui, repo, keyword="codereview.appspot.com/"+clname, limit=100, template="{node}\n").split():
				rev = repo[r]
				# Last line with a code review URL is the actual review URL.
				# Earlier ones might be part of the CL description.
				n = rev2clname(rev)
				if n == clname:
					found = True
					break
			if not found:
				return "cannot find CL %s in local repository" % clname
		else:
			rev = repo[clname]
			if not rev:
				return "unknown revision %s" % clname
			clname = rev2clname(rev)
			if clname == "":
				return "cannot find CL name in revision description"
		
		# Create fresh CL and start with patch that would reverse the change.
		vers = hg_node.short(rev.node())
		cl = CL("new")
		desc = str(rev.description())
		if mode == "undo":
			cl.desc = (undoHeader % (clname, vers)) + desc + undoFooter
		else:
			cl.desc = (backportHeader % (releaseBranch, line1(desc), clname, vers)) + desc + undoFooter
		v1 = vers
		v0 = hg_node.short(rev.parents()[0].node())
		if mode == "undo":
			arg = v1 + ":" + v0
		else:
			vers = v0
			arg = v0 + ":" + v1
		patch = RunShell(["hg", "diff", "--git", "-r", arg])

	else:  # clpatch
		cl, vers, patch, err = DownloadCL(ui, repo, clname)
		if err != "":
			return err
		if patch == emptydiff:
			return "codereview issue %s has no diff" % clname

	# find current hg version (hg identify)
	ctx = repo[None]
	parents = ctx.parents()
	id = '+'.join([hg_node.short(p.node()) for p in parents])

	# if version does not match the patch version,
	# try to update the patch line numbers.
	if vers != "" and id != vers:
		# "vers in repo" gives the wrong answer
		# on some versions of Mercurial.  Instead, do the actual
		# lookup and catch the exception.
		try:
			repo[vers].description()
		except:
			return "local repository is out of date; sync to get %s" % (vers)
		patch1, err = portPatch(repo, patch, vers, id)
		if err != "":
			if not opts["ignore_hgpatch_failure"]:
				return "codereview issue %s is out of date: %s (%s->%s)" % (clname, err, vers, id)
		else:
			patch = patch1
	argv = ["hgpatch"]
	if opts["no_incoming"] or mode == "backport":
		argv += ["--checksync=false"]
	try:
		cmd = subprocess.Popen(argv, shell=False, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=None, close_fds=sys.platform != "win32")
	except:
		return "hgpatch: " + ExceptionDetail() + "\nInstall hgpatch with:\n$ go get code.google.com/p/go.codereview/cmd/hgpatch\n"

	out, err = cmd.communicate(patch)
	if cmd.returncode != 0 and not opts["ignore_hgpatch_failure"]:
		return "hgpatch failed"
	cl.local = True
	cl.files = out.strip().split()
	if not cl.files and not opts["ignore_hgpatch_failure"]:
		return "codereview issue %s has no changed files" % clname
	files = ChangedFiles(ui, repo, [])
	extra = Sub(cl.files, files)
	if extra:
		ui.warn("warning: these files were listed in the patch but not changed:\n\t" + "\n\t".join(extra) + "\n")
	cl.Flush(ui, repo)
	if mode == "undo":
		err = EditCL(ui, repo, cl)
		if err != "":
			return "CL created, but error editing: " + err
		cl.Flush(ui, repo)
	else:
		ui.write(cl.PendingText() + "\n")

# portPatch rewrites patch from being a patch against
# oldver to being a patch against newver.
def portPatch(repo, patch, oldver, newver):
	lines = patch.splitlines(True) # True = keep \n
	delta = None
	for i in range(len(lines)):
		line = lines[i]
		if line.startswith('--- a/'):
			file = line[6:-1]
			delta = fileDeltas(repo, file, oldver, newver)
		if not delta or not line.startswith('@@ '):
			continue
		# @@ -x,y +z,w @@ means the patch chunk replaces
		# the original file's line numbers x up to x+y with the
		# line numbers z up to z+w in the new file.
		# Find the delta from x in the original to the same
		# line in the current version and add that delta to both
		# x and z.
		m = re.match('@@ -([0-9]+),([0-9]+) \+([0-9]+),([0-9]+) @@', line)
		if not m:
			return None, "error parsing patch line numbers"
		n1, len1, n2, len2 = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
		d, err = lineDelta(delta, n1, len1)
		if err != "":
			return "", err
		n1 += d
		n2 += d
		lines[i] = "@@ -%d,%d +%d,%d @@\n" % (n1, len1, n2, len2)
		
	newpatch = ''.join(lines)
	return newpatch, ""

# fileDelta returns the line number deltas for the given file's
# changes from oldver to newver.
# The deltas are a list of (n, len, newdelta) triples that say
# lines [n, n+len) were modified, and after that range the
# line numbers are +newdelta from what they were before.
def fileDeltas(repo, file, oldver, newver):
	cmd = ["hg", "diff", "--git", "-r", oldver + ":" + newver, "path:" + file]
	data = RunShell(cmd, silent_ok=True)
	deltas = []
	for line in data.splitlines():
		m = re.match('@@ -([0-9]+),([0-9]+) \+([0-9]+),([0-9]+) @@', line)
		if not m:
			continue
		n1, len1, n2, len2 = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
		deltas.append((n1, len1, n2+len2-(n1+len1)))
	return deltas

# lineDelta finds the appropriate line number delta to apply to the lines [n, n+len).
# It returns an error if those lines were rewritten by the patch.
def lineDelta(deltas, n, len):
	d = 0
	for (old, oldlen, newdelta) in deltas:
		if old >= n+len:
			break
		if old+len > n:
			return 0, "patch and recent changes conflict"
		d = newdelta
	return d, ""

@hgcommand
def download(ui, repo, clname, **opts):
	"""download a change from the code review server

	Download prints a description of the given change list
	followed by its diff, downloaded from the code review server.
	"""
	if codereview_disabled:
		return codereview_disabled

	cl, vers, patch, err = DownloadCL(ui, repo, clname)
	if err != "":
		return err
	ui.write(cl.EditorText() + "\n")
	ui.write(patch + "\n")
	return

#######################################################################
# hg file

@hgcommand
def file(ui, repo, clname, pat, *pats, **opts):
	"""assign files to or remove files from a change list

	Assign files to or (with -d) remove files from a change list.

	The -d option only removes files from the change list.
	It does not edit them or remove them from the repository.
	"""
	if codereview_disabled:
		return codereview_disabled

	pats = tuple([pat] + list(pats))
	if not GoodCLName(clname):
		return "invalid CL name " + clname

	dirty = {}
	cl, err = LoadCL(ui, repo, clname, web=False)
	if err != '':
		return err
	if not cl.local:
		return "cannot change non-local CL " + clname

	files = ChangedFiles(ui, repo, pats)

	if opts["delete"]:
		oldfiles = Intersect(files, cl.files)
		if oldfiles:
			if not ui.quiet:
				ui.status("# Removing files from CL.  To undo:\n")
				ui.status("#	cd %s\n" % (repo.root))
				for f in oldfiles:
					ui.status("#	hg file %s %s\n" % (cl.name, f))
			cl.files = Sub(cl.files, oldfiles)
			cl.Flush(ui, repo)
		else:
			ui.status("no such files in CL")
		return

	if not files:
		return "no such modified files"

	files = Sub(files, cl.files)
	taken = Taken(ui, repo)
	warned = False
	for f in files:
		if f in taken:
			if not warned and not ui.quiet:
				ui.status("# Taking files from other CLs.  To undo:\n")
				ui.status("#	cd %s\n" % (repo.root))
				warned = True
			ocl = taken[f]
			if not ui.quiet:
				ui.status("#	hg file %s %s\n" % (ocl.name, f))
			if ocl not in dirty:
				ocl.files = Sub(ocl.files, files)
				dirty[ocl] = True
	cl.files = Add(cl.files, files)
	dirty[cl] = True
	for d, _ in dirty.items():
		d.Flush(ui, repo)
	return

#######################################################################
# hg gofmt

@hgcommand
def gofmt(ui, repo, *pats, **opts):
	"""apply gofmt to modified files

	Applies gofmt to the modified files in the repository that match
	the given patterns.
	"""
	if codereview_disabled:
		return codereview_disabled

	files = ChangedExistingFiles(ui, repo, pats, opts)
	files = gofmt_required(files)
	if not files:
		return "no modified go files"
	cwd = os.getcwd()
	files = [RelativePath(repo.root + '/' + f, cwd) for f in files]
	try:
		cmd = ["gofmt", "-l"]
		if not opts["list"]:
			cmd += ["-w"]
		if os.spawnvp(os.P_WAIT, "gofmt", cmd + files) != 0:
			raise hg_util.Abort("gofmt did not exit cleanly")
	except hg_error.Abort, e:
		raise
	except:
		raise hg_util.Abort("gofmt: " + ExceptionDetail())
	return

def gofmt_required(files):
	return [f for f in files if (not f.startswith('test/') or f.startswith('test/bench/')) and f.endswith('.go')]

#######################################################################
# hg mail

@hgcommand
def mail(ui, repo, *pats, **opts):
	"""mail a change for review

	Uploads a patch to the code review server and then sends mail
	to the reviewer and CC list asking for a review.
	"""
	if codereview_disabled:
		return codereview_disabled

	cl, err = CommandLineCL(ui, repo, pats, opts, defaultcc=defaultcc)
	if err != "":
		return err
	cl.Upload(ui, repo, gofmt_just_warn=True)
	if not cl.reviewer:
		# If no reviewer is listed, assign the review to defaultcc.
		# This makes sure that it appears in the 
		# codereview.appspot.com/user/defaultcc
		# page, so that it doesn't get dropped on the floor.
		if not defaultcc:
			return "no reviewers listed in CL"
		cl.cc = Sub(cl.cc, defaultcc)
		cl.reviewer = defaultcc
		cl.Flush(ui, repo)

	if cl.files == []:
		return "no changed files, not sending mail"

	cl.Mail(ui, repo)		

#######################################################################
# hg p / hg pq / hg ps / hg pending

@hgcommand
def ps(ui, repo, *pats, **opts):
	"""alias for hg p --short
	"""
	opts['short'] = True
	return pending(ui, repo, *pats, **opts)

@hgcommand
def pq(ui, repo, *pats, **opts):
	"""alias for hg p --quick
	"""
	opts['quick'] = True
	return pending(ui, repo, *pats, **opts)

@hgcommand
def pending(ui, repo, *pats, **opts):
	"""show pending changes

	Lists pending changes followed by a list of unassigned but modified files.
	"""
	if codereview_disabled:
		return codereview_disabled

	quick = opts.get('quick', False)
	short = opts.get('short', False)
	m = LoadAllCL(ui, repo, web=not quick and not short)
	names = m.keys()
	names.sort()
	for name in names:
		cl = m[name]
		if short:
			ui.write(name + "\t" + line1(cl.desc) + "\n")
		else:
			ui.write(cl.PendingText(quick=quick) + "\n")

	if short:
		return
	files = DefaultFiles(ui, repo, [])
	if len(files) > 0:
		s = "Changed files not in any CL:\n"
		for f in files:
			s += "\t" + f + "\n"
		ui.write(s)

#######################################################################
# hg submit

def need_sync():
	raise hg_util.Abort("local repository out of date; must sync before submit")

@hgcommand
def submit(ui, repo, *pats, **opts):
	"""submit change to remote repository

	Submits change to remote repository.
	Bails out if the local repository is not in sync with the remote one.
	"""
	if codereview_disabled:
		return codereview_disabled

	# We already called this on startup but sometimes Mercurial forgets.
	set_mercurial_encoding_to_utf8()

	if not opts["no_incoming"] and hg_incoming(ui, repo):
		need_sync()

	cl, err = CommandLineCL(ui, repo, pats, opts, defaultcc=defaultcc)
	if err != "":
		return err

	user = None
	if cl.copied_from:
		user = cl.copied_from
	userline = CheckContributor(ui, repo, user)
	typecheck(userline, str)

	about = ""
	if cl.reviewer:
		about += "R=" + JoinComma([CutDomain(s) for s in cl.reviewer]) + "\n"
	if opts.get('tbr'):
		tbr = SplitCommaSpace(opts.get('tbr'))
		cl.reviewer = Add(cl.reviewer, tbr)
		about += "TBR=" + JoinComma([CutDomain(s) for s in tbr]) + "\n"
	if cl.cc:
		about += "CC=" + JoinComma([CutDomain(s) for s in cl.cc]) + "\n"

	if not cl.reviewer:
		return "no reviewers listed in CL"

	if not cl.local:
		return "cannot submit non-local CL"

	# upload, to sync current patch and also get change number if CL is new.
	if not cl.copied_from:
		cl.Upload(ui, repo, gofmt_just_warn=True)

	# check gofmt for real; allowed upload to warn in order to save CL.
	cl.Flush(ui, repo)
	CheckFormat(ui, repo, cl.files)

	about += "%s%s\n" % (server_url_base, cl.name)

	if cl.copied_from:
		about += "\nCommitter: " + CheckContributor(ui, repo, None) + "\n"
	typecheck(about, str)

	if not cl.mailed and not cl.copied_from:		# in case this is TBR
		cl.Mail(ui, repo)

	# submit changes locally
	message = cl.desc.rstrip() + "\n\n" + about
	typecheck(message, str)

	set_status("pushing " + cl.name + " to remote server")

	if hg_outgoing(ui, repo):
		raise hg_util.Abort("local repository corrupt or out-of-phase with remote: found outgoing changes")
	
	old_heads = len(hg_heads(ui, repo).split())

	global commit_okay
	commit_okay = True
	ret = hg_commit(ui, repo, *['path:'+f for f in cl.files], message=message, user=userline)
	commit_okay = False
	if ret:
		return "nothing changed"
	node = repo["-1"].node()
	# push to remote; if it fails for any reason, roll back
	try:
		new_heads = len(hg_heads(ui, repo).split())
		if old_heads != new_heads and not (old_heads == 0 and new_heads == 1):
			# Created new head, so we weren't up to date.
			need_sync()

		# Push changes to remote.  If it works, we're committed.  If not, roll back.
		try:
			hg_push(ui, repo)
		except hg_error.Abort, e:
			if e.message.find("push creates new heads") >= 0:
				# Remote repository had changes we missed.
				need_sync()
			raise
	except:
		real_rollback()
		raise

	# We're committed. Upload final patch, close review, add commit message.
	changeURL = hg_node.short(node)
	url = ui.expandpath("default")
	m = re.match("(^https?://([^@/]+@)?([^.]+)\.googlecode\.com/hg/?)" + "|" +
		"(^https?://([^@/]+@)?code\.google\.com/p/([^/.]+)(\.[^./]+)?/?)", url)
	if m:
		if m.group(1): # prj.googlecode.com/hg/ case
			changeURL = "http://code.google.com/p/%s/source/detail?r=%s" % (m.group(3), changeURL)
		elif m.group(4) and m.group(7): # code.google.com/p/prj.subrepo/ case
			changeURL = "http://code.google.com/p/%s/source/detail?r=%s&repo=%s" % (m.group(6), changeURL, m.group(7)[1:])
		elif m.group(4): # code.google.com/p/prj/ case
			changeURL = "http://code.google.com/p/%s/source/detail?r=%s" % (m.group(6), changeURL)
		else:
			print >>sys.stderr, "URL: ", url
	else:
		print >>sys.stderr, "URL: ", url
	pmsg = "*** Submitted as " + changeURL + " ***\n\n" + message

	# When posting, move reviewers to CC line,
	# so that the issue stops showing up in their "My Issues" page.
	PostMessage(ui, cl.name, pmsg, reviewers="", cc=JoinComma(cl.reviewer+cl.cc))

	if not cl.copied_from:
		EditDesc(cl.name, closed=True, private=cl.private)
	cl.Delete(ui, repo)

	c = repo[None]
	if c.branch() == releaseBranch and not c.modified() and not c.added() and not c.removed():
		ui.write("switching from %s to default branch.\n" % releaseBranch)
		err = hg_clean(repo, "default")
		if err:
			return err
	return None

#######################################################################
# hg sync

@hgcommand
def sync(ui, repo, **opts):
	"""synchronize with remote repository

	Incorporates recent changes from the remote repository
	into the local repository.
	"""
	if codereview_disabled:
		return codereview_disabled

	if not opts["local"]:
		err = hg_pull(ui, repo, update=True)
		if err:
			return err
	sync_changes(ui, repo)

def sync_changes(ui, repo):
	# Look through recent change log descriptions to find
	# potential references to http://.*/our-CL-number.
	# Double-check them by looking at the Rietveld log.
	for rev in hg_log(ui, repo, limit=100, template="{node}\n").split():
		desc = repo[rev].description().strip()
		for clname in re.findall('(?m)^http://(?:[^\n]+)/([0-9]+)$', desc):
			if IsLocalCL(ui, repo, clname) and IsRietveldSubmitted(ui, clname, repo[rev].hex()):
				ui.warn("CL %s submitted as %s; closing\n" % (clname, repo[rev]))
				cl, err = LoadCL(ui, repo, clname, web=False)
				if err != "":
					ui.warn("loading CL %s: %s\n" % (clname, err))
					continue
				if not cl.copied_from:
					EditDesc(cl.name, closed=True, private=cl.private)
				cl.Delete(ui, repo)

	# Remove files that are not modified from the CLs in which they appear.
	all = LoadAllCL(ui, repo, web=False)
	changed = ChangedFiles(ui, repo, [])
	for cl in all.values():
		extra = Sub(cl.files, changed)
		if extra:
			ui.warn("Removing unmodified files from CL %s:\n" % (cl.name,))
			for f in extra:
				ui.warn("\t%s\n" % (f,))
			cl.files = Sub(cl.files, extra)
			cl.Flush(ui, repo)
		if not cl.files:
			if not cl.copied_from:
				ui.warn("CL %s has no files; delete (abandon) with hg change -d %s\n" % (cl.name, cl.name))
			else:
				ui.warn("CL %s has no files; delete locally with hg change -D %s\n" % (cl.name, cl.name))
	return

#######################################################################
# hg upload

@hgcommand
def upload(ui, repo, name, **opts):
	"""upload diffs to the code review server

	Uploads the current modifications for a given change to the server.
	"""
	if codereview_disabled:
		return codereview_disabled

	repo.ui.quiet = True
	cl, err = LoadCL(ui, repo, name, web=True)
	if err != "":
		return err
	if not cl.local:
		return "cannot upload non-local change"
	cl.Upload(ui, repo)
	print "%s%s\n" % (server_url_base, cl.name)
	return

#######################################################################
# Table of commands, supplied to Mercurial for installation.

review_opts = [
	('r', 'reviewer', '', 'add reviewer'),
	('', 'cc', '', 'add cc'),
	('', 'tbr', '', 'add future reviewer'),
	('m', 'message', '', 'change description (for new change)'),
]

cmdtable = {
	# The ^ means to show this command in the help text that
	# is printed when running hg with no arguments.
	"^change": (
		change,
		[
			('d', 'delete', None, 'delete existing change list'),
			('D', 'deletelocal', None, 'delete locally, but do not change CL on server'),
			('i', 'stdin', None, 'read change list from standard input'),
			('o', 'stdout', None, 'print change list to standard output'),
			('p', 'pending', None, 'print pending summary to standard output'),
		],
		"[-d | -D] [-i] [-o] change# or FILE ..."
	),
	"^clpatch": (
		clpatch,
		[
			('', 'ignore_hgpatch_failure', None, 'create CL metadata even if hgpatch fails'),
			('', 'no_incoming', None, 'disable check for incoming changes'),
		],
		"change#"
	),
	# Would prefer to call this codereview-login, but then
	# hg help codereview prints the help for this command
	# instead of the help for the extension.
	"code-login": (
		code_login,
		[],
		"",
	),
	"^download": (
		download,
		[],
		"change#"
	),
	"^file": (
		file,
		[
			('d', 'delete', None, 'delete files from change list (but not repository)'),
		],
		"[-d] change# FILE ..."
	),
	"^gofmt": (
		gofmt,
		[
			('l', 'list', None, 'list files that would change, but do not edit them'),
		],
		"FILE ..."
	),
	"^pending|p": (
		pending,
		[
			('s', 'short', False, 'show short result form'),
			('', 'quick', False, 'do not consult codereview server'),
		],
		"[FILE ...]"
	),
	"^ps": (
		ps,
		[],
		"[FILE ...]"
	),
	"^pq": (
		pq,
		[],
		"[FILE ...]"
	),
	"^mail": (
		mail,
		review_opts + [
		] + hg_commands.walkopts,
		"[-r reviewer] [--cc cc] [change# | file ...]"
	),
	"^release-apply": (
		release_apply,
		[
			('', 'ignore_hgpatch_failure', None, 'create CL metadata even if hgpatch fails'),
			('', 'no_incoming', None, 'disable check for incoming changes'),
		],
		"change#"
	),
	# TODO: release-start, release-tag, weekly-tag
	"^submit": (
		submit,
		review_opts + [
			('', 'no_incoming', None, 'disable initial incoming check (for testing)'),
		] + hg_commands.walkopts + hg_commands.commitopts + hg_commands.commitopts2,
		"[-r reviewer] [--cc cc] [change# | file ...]"
	),
	"^sync": (
		sync,
		[
			('', 'local', None, 'do not pull changes from remote repository')
		],
		"[--local]",
	),
	"^undo": (
		undo,
		[
			('', 'ignore_hgpatch_failure', None, 'create CL metadata even if hgpatch fails'),
			('', 'no_incoming', None, 'disable check for incoming changes'),
		],
		"change#"
	),
	"^upload": (
		upload,
		[],
		"change#"
	),
}

#######################################################################
# Mercurial extension initialization

def norollback(*pats, **opts):
	"""(disabled when using this extension)"""
	raise hg_util.Abort("codereview extension enabled; use undo instead of rollback")

codereview_init = False

def reposetup(ui, repo):
	global codereview_disabled
	global defaultcc
	
	# reposetup gets called both for the local repository
	# and also for any repository we are pulling or pushing to.
	# Only initialize the first time.
	global codereview_init
	if codereview_init:
		return
	codereview_init = True

	# Read repository-specific options from lib/codereview/codereview.cfg or codereview.cfg.
	root = ''
	try:
		root = repo.root
	except:
		# Yes, repo might not have root; see issue 959.
		codereview_disabled = 'codereview disabled: repository has no root'
		return
	
	repo_config_path = ''
	p1 = root + '/lib/codereview/codereview.cfg'
	p2 = root + '/codereview.cfg'
	if os.access(p1, os.F_OK):
		repo_config_path = p1
	else:
		repo_config_path = p2
	try:
		f = open(repo_config_path)
		for line in f:
			if line.startswith('defaultcc:'):
				defaultcc = SplitCommaSpace(line[len('defaultcc:'):])
			if line.startswith('contributors:'):
				global contributorsURL
				contributorsURL = line[len('contributors:'):].strip()
	except:
		codereview_disabled = 'codereview disabled: cannot open ' + repo_config_path
		return

	remote = ui.config("paths", "default", "")
	if remote.find("://") < 0:
		raise hg_util.Abort("codereview: default path '%s' is not a URL" % (remote,))

	InstallMatch(ui, repo)
	RietveldSetup(ui, repo)

	# Disable the Mercurial commands that might change the repository.
	# Only commands in this extension are supposed to do that.
	ui.setconfig("hooks", "precommit.codereview", precommithook)

	# Rollback removes an existing commit.  Don't do that either.
	global real_rollback
	real_rollback = repo.rollback
	repo.rollback = norollback
	

#######################################################################
# Wrappers around upload.py for interacting with Rietveld

from HTMLParser import HTMLParser

# HTML form parser
class FormParser(HTMLParser):
	def __init__(self):
		self.map = {}
		self.curtag = None
		self.curdata = None
		HTMLParser.__init__(self)
	def handle_starttag(self, tag, attrs):
		if tag == "input":
			key = None
			value = ''
			for a in attrs:
				if a[0] == 'name':
					key = a[1]
				if a[0] == 'value':
					value = a[1]
			if key is not None:
				self.map[key] = value
		if tag == "textarea":
			key = None
			for a in attrs:
				if a[0] == 'name':
					key = a[1]
			if key is not None:
				self.curtag = key
				self.curdata = ''
	def handle_endtag(self, tag):
		if tag == "textarea" and self.curtag is not None:
			self.map[self.curtag] = self.curdata
			self.curtag = None
			self.curdata = None
	def handle_charref(self, name):
		self.handle_data(unichr(int(name)))
	def handle_entityref(self, name):
		import htmlentitydefs
		if name in htmlentitydefs.entitydefs:
			self.handle_data(htmlentitydefs.entitydefs[name])
		else:
			self.handle_data("&" + name + ";")
	def handle_data(self, data):
		if self.curdata is not None:
			self.curdata += data

def JSONGet(ui, path):
	try:
		data = MySend(path, force_auth=False)
		typecheck(data, str)
		d = fix_json(json.loads(data))
	except:
		ui.warn("JSONGet %s: %s\n" % (path, ExceptionDetail()))
		return None
	return d

# Clean up json parser output to match our expectations:
#   * all strings are UTF-8-encoded str, not unicode.
#   * missing fields are missing, not None,
#     so that d.get("foo", defaultvalue) works.
def fix_json(x):
	if type(x) in [str, int, float, bool, type(None)]:
		pass
	elif type(x) is unicode:
		x = x.encode("utf-8")
	elif type(x) is list:
		for i in range(len(x)):
			x[i] = fix_json(x[i])
	elif type(x) is dict:
		todel = []
		for k in x:
			if x[k] is None:
				todel.append(k)
			else:
				x[k] = fix_json(x[k])
		for k in todel:
			del x[k]
	else:
		raise hg_util.Abort("unknown type " + str(type(x)) + " in fix_json")
	if type(x) is str:
		x = x.replace('\r\n', '\n')
	return x

def IsRietveldSubmitted(ui, clname, hex):
	dict = JSONGet(ui, "/api/" + clname + "?messages=true")
	if dict is None:
		return False
	for msg in dict.get("messages", []):
		text = msg.get("text", "")
		m = re.match('\*\*\* Submitted as [^*]*?([0-9a-f]+) \*\*\*', text)
		if m is not None and len(m.group(1)) >= 8 and hex.startswith(m.group(1)):
			return True
	return False

def IsRietveldMailed(cl):
	for msg in cl.dict.get("messages", []):
		if msg.get("text", "").find("I'd like you to review this change") >= 0:
			return True
	return False

def DownloadCL(ui, repo, clname):
	set_status("downloading CL " + clname)
	cl, err = LoadCL(ui, repo, clname, web=True)
	if err != "":
		return None, None, None, "error loading CL %s: %s" % (clname, err)

	# Find most recent diff
	diffs = cl.dict.get("patchsets", [])
	if not diffs:
		return None, None, None, "CL has no patch sets"
	patchid = diffs[-1]

	patchset = JSONGet(ui, "/api/" + clname + "/" + str(patchid))
	if patchset is None:
		return None, None, None, "error loading CL patchset %s/%d" % (clname, patchid)
	if patchset.get("patchset", 0) != patchid:
		return None, None, None, "malformed patchset information"
	
	vers = ""
	msg = patchset.get("message", "").split()
	if len(msg) >= 3 and msg[0] == "diff" and msg[1] == "-r":
		vers = msg[2]
	diff = "/download/issue" + clname + "_" + str(patchid) + ".diff"

	diffdata = MySend(diff, force_auth=False)
	
	# Print warning if email is not in CONTRIBUTORS file.
	email = cl.dict.get("owner_email", "")
	if not email:
		return None, None, None, "cannot find owner for %s" % (clname)
	him = FindContributor(ui, repo, email)
	me = FindContributor(ui, repo, None)
	if him == me:
		cl.mailed = IsRietveldMailed(cl)
	else:
		cl.copied_from = email

	return cl, vers, diffdata, ""

def MySend(request_path, payload=None,
		content_type="application/octet-stream",
		timeout=None, force_auth=True,
		**kwargs):
	"""Run MySend1 maybe twice, because Rietveld is unreliable."""
	try:
		return MySend1(request_path, payload, content_type, timeout, force_auth, **kwargs)
	except Exception, e:
		if type(e) != urllib2.HTTPError or e.code != 500:	# only retry on HTTP 500 error
			raise
		print >>sys.stderr, "Loading "+request_path+": "+ExceptionDetail()+"; trying again in 2 seconds."
		time.sleep(2)
		return MySend1(request_path, payload, content_type, timeout, force_auth, **kwargs)

# Like upload.py Send but only authenticates when the
# redirect is to www.google.com/accounts.  This keeps
# unnecessary redirects from happening during testing.
def MySend1(request_path, payload=None,
				content_type="application/octet-stream",
				timeout=None, force_auth=True,
				**kwargs):
	"""Sends an RPC and returns the response.

	Args:
		request_path: The path to send the request to, eg /api/appversion/create.
		payload: The body of the request, or None to send an empty request.
		content_type: The Content-Type header to use.
		timeout: timeout in seconds; default None i.e. no timeout.
			(Note: for large requests on OS X, the timeout doesn't work right.)
		kwargs: Any keyword arguments are converted into query string parameters.

	Returns:
		The response body, as a string.
	"""
	# TODO: Don't require authentication.  Let the server say
	# whether it is necessary.
	global rpc
	if rpc == None:
		rpc = GetRpcServer(upload_options)
	self = rpc
	if not self.authenticated and force_auth:
		self._Authenticate()
	if request_path is None:
		return

	old_timeout = socket.getdefaulttimeout()
	socket.setdefaulttimeout(timeout)
	try:
		tries = 0
		while True:
			tries += 1
			args = dict(kwargs)
			url = "http://%s%s" % (self.host, request_path)
			if args:
				url += "?" + urllib.urlencode(args)
			req = self._CreateRequest(url=url, data=payload)
			req.add_header("Content-Type", content_type)
			try:
				f = self.opener.open(req)
				response = f.read()
				f.close()
				# Translate \r\n into \n, because Rietveld doesn't.
				response = response.replace('\r\n', '\n')
				# who knows what urllib will give us
				if type(response) == unicode:
					response = response.encode("utf-8")
				typecheck(response, str)
				return response
			except urllib2.HTTPError, e:
				if tries > 3:
					raise
				elif e.code == 401:
					self._Authenticate()
				elif e.code == 302:
					loc = e.info()["location"]
					if not loc.startswith('https://www.google.com/a') or loc.find('/ServiceLogin') < 0:
						return ''
					self._Authenticate()
				else:
					raise
	finally:
		socket.setdefaulttimeout(old_timeout)

def GetForm(url):
	f = FormParser()
	f.feed(ustr(MySend(url)))	# f.feed wants unicode
	f.close()
	# convert back to utf-8 to restore sanity
	m = {}
	for k,v in f.map.items():
		m[k.encode("utf-8")] = v.replace("\r\n", "\n").encode("utf-8")
	return m

def EditDesc(issue, subject=None, desc=None, reviewers=None, cc=None, closed=False, private=False):
	set_status("uploading change to description")
	form_fields = GetForm("/" + issue + "/edit")
	if subject is not None:
		form_fields['subject'] = subject
	if desc is not None:
		form_fields['description'] = desc
	if reviewers is not None:
		form_fields['reviewers'] = reviewers
	if cc is not None:
		form_fields['cc'] = cc
	if closed:
		form_fields['closed'] = "checked"
	if private:
		form_fields['private'] = "checked"
	ctype, body = EncodeMultipartFormData(form_fields.items(), [])
	response = MySend("/" + issue + "/edit", body, content_type=ctype)
	if response != "":
		print >>sys.stderr, "Error editing description:\n" + "Sent form: \n", form_fields, "\n", response
		sys.exit(2)

def PostMessage(ui, issue, message, reviewers=None, cc=None, send_mail=True, subject=None):
	set_status("uploading message")
	form_fields = GetForm("/" + issue + "/publish")
	if reviewers is not None:
		form_fields['reviewers'] = reviewers
	if cc is not None:
		form_fields['cc'] = cc
	if send_mail:
		form_fields['send_mail'] = "checked"
	else:
		del form_fields['send_mail']
	if subject is not None:
		form_fields['subject'] = subject
	form_fields['message'] = message
	
	form_fields['message_only'] = '1'	# Don't include draft comments
	if reviewers is not None or cc is not None:
		form_fields['message_only'] = ''	# Must set '' in order to override cc/reviewer
	ctype = "applications/x-www-form-urlencoded"
	body = urllib.urlencode(form_fields)
	response = MySend("/" + issue + "/publish", body, content_type=ctype)
	if response != "":
		print response
		sys.exit(2)

class opt(object):
	pass

def RietveldSetup(ui, repo):
	global force_google_account
	global rpc
	global server
	global server_url_base
	global upload_options
	global verbosity

	if not ui.verbose:
		verbosity = 0

	# Config options.
	x = ui.config("codereview", "server")
	if x is not None:
		server = x

	# TODO(rsc): Take from ui.username?
	email = None
	x = ui.config("codereview", "email")
	if x is not None:
		email = x

	server_url_base = "http://" + server + "/"

	testing = ui.config("codereview", "testing")
	force_google_account = ui.configbool("codereview", "force_google_account", False)

	upload_options = opt()
	upload_options.email = email
	upload_options.host = None
	upload_options.verbose = 0
	upload_options.description = None
	upload_options.description_file = None
	upload_options.reviewers = None
	upload_options.cc = None
	upload_options.message = None
	upload_options.issue = None
	upload_options.download_base = False
	upload_options.revision = None
	upload_options.send_mail = False
	upload_options.vcs = None
	upload_options.server = server
	upload_options.save_cookies = True

	if testing:
		upload_options.save_cookies = False
		upload_options.email = "test@example.com"

	rpc = None
	
	global releaseBranch
	tags = repo.branchmap().keys()
	if 'release-branch.go10' in tags:
		# NOTE(rsc): This tags.sort is going to get the wrong
		# answer when comparing release-branch.go9 with
		# release-branch.go10.  It will be a while before we care.
		raise hg_util.Abort('tags.sort needs to be fixed for release-branch.go10')
	tags.sort()
	for t in tags:
		if t.startswith('release-branch.go'):
			releaseBranch = t			

#######################################################################
# http://codereview.appspot.com/static/upload.py, heavily edited.

#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Tool for uploading diffs from a version control system to the codereview app.

Usage summary: upload.py [options] [-- diff_options]

Diff options are passed to the diff command of the underlying system.

Supported version control systems:
	Git
	Mercurial
	Subversion

It is important for Git/Mercurial users to specify a tree/node/branch to diff
against by using the '--rev' option.
"""
# This code is derived from appcfg.py in the App Engine SDK (open source),
# and from ASPN recipe #146306.

import cookielib
import getpass
import logging
import mimetypes
import optparse
import os
import re
import socket
import subprocess
import sys
import urllib
import urllib2
import urlparse

# The md5 module was deprecated in Python 2.5.
try:
	from hashlib import md5
except ImportError:
	from md5 import md5

try:
	import readline
except ImportError:
	pass

# The logging verbosity:
#  0: Errors only.
#  1: Status messages.
#  2: Info logs.
#  3: Debug logs.
verbosity = 1

# Max size of patch or base file.
MAX_UPLOAD_SIZE = 900 * 1024

# whitelist for non-binary filetypes which do not start with "text/"
# .mm (Objective-C) shows up as application/x-freemind on my Linux box.
TEXT_MIMETYPES = [
	'application/javascript',
	'application/x-javascript',
	'application/x-freemind'
]

def GetEmail(prompt):
	"""Prompts the user for their email address and returns it.

	The last used email address is saved to a file and offered up as a suggestion
	to the user. If the user presses enter without typing in anything the last
	used email address is used. If the user enters a new address, it is saved
	for next time we prompt.

	"""
	last_email_file_name = os.path.expanduser("~/.last_codereview_email_address")
	last_email = ""
	if os.path.exists(last_email_file_name):
		try:
			last_email_file = open(last_email_file_name, "r")
			last_email = last_email_file.readline().strip("\n")
			last_email_file.close()
			prompt += " [%s]" % last_email
		except IOError, e:
			pass
	email = raw_input(prompt + ": ").strip()
	if email:
		try:
			last_email_file = open(last_email_file_name, "w")
			last_email_file.write(email)
			last_email_file.close()
		except IOError, e:
			pass
	else:
		email = last_email
	return email


def StatusUpdate(msg):
	"""Print a status message to stdout.

	If 'verbosity' is greater than 0, print the message.

	Args:
		msg: The string to print.
	"""
	if verbosity > 0:
		print msg


def ErrorExit(msg):
	"""Print an error message to stderr and exit."""
	print >>sys.stderr, msg
	sys.exit(1)


class ClientLoginError(urllib2.HTTPError):
	"""Raised to indicate there was an error authenticating with ClientLogin."""

	def __init__(self, url, code, msg, headers, args):
		urllib2.HTTPError.__init__(self, url, code, msg, headers, None)
		self.args = args
		self.reason = args["Error"]


class AbstractRpcServer(object):
	"""Provides a common interface for a simple RPC server."""

	def __init__(self, host, auth_function, host_override=None, extra_headers={}, save_cookies=False):
		"""Creates a new HttpRpcServer.

		Args:
			host: The host to send requests to.
			auth_function: A function that takes no arguments and returns an
				(email, password) tuple when called. Will be called if authentication
				is required.
			host_override: The host header to send to the server (defaults to host).
			extra_headers: A dict of extra headers to append to every request.
			save_cookies: If True, save the authentication cookies to local disk.
				If False, use an in-memory cookiejar instead.  Subclasses must
				implement this functionality.  Defaults to False.
		"""
		self.host = host
		self.host_override = host_override
		self.auth_function = auth_function
		self.authenticated = False
		self.extra_headers = extra_headers
		self.save_cookies = save_cookies
		self.opener = self._GetOpener()
		if self.host_override:
			logging.info("Server: %s; Host: %s", self.host, self.host_override)
		else:
			logging.info("Server: %s", self.host)

	def _GetOpener(self):
		"""Returns an OpenerDirector for making HTTP requests.

		Returns:
			A urllib2.OpenerDirector object.
		"""
		raise NotImplementedError()

	def _CreateRequest(self, url, data=None):
		"""Creates a new urllib request."""
		logging.debug("Creating request for: '%s' with payload:\n%s", url, data)
		req = urllib2.Request(url, data=data)
		if self.host_override:
			req.add_header("Host", self.host_override)
		for key, value in self.extra_headers.iteritems():
			req.add_header(key, value)
		return req

	def _GetAuthToken(self, email, password):
		"""Uses ClientLogin to authenticate the user, returning an auth token.

		Args:
			email:    The user's email address
			password: The user's password

		Raises:
			ClientLoginError: If there was an error authenticating with ClientLogin.
			HTTPError: If there was some other form of HTTP error.

		Returns:
			The authentication token returned by ClientLogin.
		"""
		account_type = "GOOGLE"
		if self.host.endswith(".google.com") and not force_google_account:
			# Needed for use inside Google.
			account_type = "HOSTED"
		req = self._CreateRequest(
				url="https://www.google.com/accounts/ClientLogin",
				data=urllib.urlencode({
						"Email": email,
						"Passwd": password,
						"service": "ah",
						"source": "rietveld-codereview-upload",
						"accountType": account_type,
				}),
		)
		try:
			response = self.opener.open(req)
			response_body = response.read()
			response_dict = dict(x.split("=") for x in response_body.split("\n") if x)
			return response_dict["Auth"]
		except urllib2.HTTPError, e:
			if e.code == 403:
				body = e.read()
				response_dict = dict(x.split("=", 1) for x in body.split("\n") if x)
				raise ClientLoginError(req.get_full_url(), e.code, e.msg, e.headers, response_dict)
			else:
				raise

	def _GetAuthCookie(self, auth_token):
		"""Fetches authentication cookies for an authentication token.

		Args:
			auth_token: The authentication token returned by ClientLogin.

		Raises:
			HTTPError: If there was an error fetching the authentication cookies.
		"""
		# This is a dummy value to allow us to identify when we're successful.
		continue_location = "http://localhost/"
		args = {"continue": continue_location, "auth": auth_token}
		req = self._CreateRequest("http://%s/_ah/login?%s" % (self.host, urllib.urlencode(args)))
		try:
			response = self.opener.open(req)
		except urllib2.HTTPError, e:
			response = e
		if (response.code != 302 or
				response.info()["location"] != continue_location):
			raise urllib2.HTTPError(req.get_full_url(), response.code, response.msg, response.headers, response.fp)
		self.authenticated = True

	def _Authenticate(self):
		"""Authenticates the user.

		The authentication process works as follows:
		1) We get a username and password from the user
		2) We use ClientLogin to obtain an AUTH token for the user
				(see http://code.google.com/apis/accounts/AuthForInstalledApps.html).
		3) We pass the auth token to /_ah/login on the server to obtain an
				authentication cookie. If login was successful, it tries to redirect
				us to the URL we provided.

		If we attempt to access the upload API without first obtaining an
		authentication cookie, it returns a 401 response (or a 302) and
		directs us to authenticate ourselves with ClientLogin.
		"""
		for i in range(3):
			credentials = self.auth_function()
			try:
				auth_token = self._GetAuthToken(credentials[0], credentials[1])
			except ClientLoginError, e:
				if e.reason == "BadAuthentication":
					print >>sys.stderr, "Invalid username or password."
					continue
				if e.reason == "CaptchaRequired":
					print >>sys.stderr, (
						"Please go to\n"
						"https://www.google.com/accounts/DisplayUnlockCaptcha\n"
						"and verify you are a human.  Then try again.")
					break
				if e.reason == "NotVerified":
					print >>sys.stderr, "Account not verified."
					break
				if e.reason == "TermsNotAgreed":
					print >>sys.stderr, "User has not agreed to TOS."
					break
				if e.reason == "AccountDeleted":
					print >>sys.stderr, "The user account has been deleted."
					break
				if e.reason == "AccountDisabled":
					print >>sys.stderr, "The user account has been disabled."
					break
				if e.reason == "ServiceDisabled":
					print >>sys.stderr, "The user's access to the service has been disabled."
					break
				if e.reason == "ServiceUnavailable":
					print >>sys.stderr, "The service is not available; try again later."
					break
				raise
			self._GetAuthCookie(auth_token)
			return

	def Send(self, request_path, payload=None,
					content_type="application/octet-stream",
					timeout=None,
					**kwargs):
		"""Sends an RPC and returns the response.

		Args:
			request_path: The path to send the request to, eg /api/appversion/create.
			payload: The body of the request, or None to send an empty request.
			content_type: The Content-Type header to use.
			timeout: timeout in seconds; default None i.e. no timeout.
				(Note: for large requests on OS X, the timeout doesn't work right.)
			kwargs: Any keyword arguments are converted into query string parameters.

		Returns:
			The response body, as a string.
		"""
		# TODO: Don't require authentication.  Let the server say
		# whether it is necessary.
		if not self.authenticated:
			self._Authenticate()

		old_timeout = socket.getdefaulttimeout()
		socket.setdefaulttimeout(timeout)
		try:
			tries = 0
			while True:
				tries += 1
				args = dict(kwargs)
				url = "http://%s%s" % (self.host, request_path)
				if args:
					url += "?" + urllib.urlencode(args)
				req = self._CreateRequest(url=url, data=payload)
				req.add_header("Content-Type", content_type)
				try:
					f = self.opener.open(req)
					response = f.read()
					f.close()
					return response
				except urllib2.HTTPError, e:
					if tries > 3:
						raise
					elif e.code == 401 or e.code == 302:
						self._Authenticate()
					else:
						raise
		finally:
			socket.setdefaulttimeout(old_timeout)


class HttpRpcServer(AbstractRpcServer):
	"""Provides a simplified RPC-style interface for HTTP requests."""

	def _Authenticate(self):
		"""Save the cookie jar after authentication."""
		super(HttpRpcServer, self)._Authenticate()
		if self.save_cookies:
			StatusUpdate("Saving authentication cookies to %s" % self.cookie_file)
			self.cookie_jar.save()

	def _GetOpener(self):
		"""Returns an OpenerDirector that supports cookies and ignores redirects.

		Returns:
			A urllib2.OpenerDirector object.
		"""
		opener = urllib2.OpenerDirector()
		opener.add_handler(urllib2.ProxyHandler())
		opener.add_handler(urllib2.UnknownHandler())
		opener.add_handler(urllib2.HTTPHandler())
		opener.add_handler(urllib2.HTTPDefaultErrorHandler())
		opener.add_handler(urllib2.HTTPSHandler())
		opener.add_handler(urllib2.HTTPErrorProcessor())
		if self.save_cookies:
			self.cookie_file = os.path.expanduser("~/.codereview_upload_cookies_" + server)
			self.cookie_jar = cookielib.MozillaCookieJar(self.cookie_file)
			if os.path.exists(self.cookie_file):
				try:
					self.cookie_jar.load()
					self.authenticated = True
					StatusUpdate("Loaded authentication cookies from %s" % self.cookie_file)
				except (cookielib.LoadError, IOError):
					# Failed to load cookies - just ignore them.
					pass
			else:
				# Create an empty cookie file with mode 600
				fd = os.open(self.cookie_file, os.O_CREAT, 0600)
				os.close(fd)
			# Always chmod the cookie file
			os.chmod(self.cookie_file, 0600)
		else:
			# Don't save cookies across runs of update.py.
			self.cookie_jar = cookielib.CookieJar()
		opener.add_handler(urllib2.HTTPCookieProcessor(self.cookie_jar))
		return opener


def GetRpcServer(options):
	"""Returns an instance of an AbstractRpcServer.

	Returns:
		A new AbstractRpcServer, on which RPC calls can be made.
	"""

	rpc_server_class = HttpRpcServer

	def GetUserCredentials():
		"""Prompts the user for a username and password."""
		# Disable status prints so they don't obscure the password prompt.
		global global_status
		st = global_status
		global_status = None

		email = options.email
		if email is None:
			email = GetEmail("Email (login for uploading to %s)" % options.server)
		password = getpass.getpass("Password for %s: " % email)

		# Put status back.
		global_status = st
		return (email, password)

	# If this is the dev_appserver, use fake authentication.
	host = (options.host or options.server).lower()
	if host == "localhost" or host.startswith("localhost:"):
		email = options.email
		if email is None:
			email = "test@example.com"
			logging.info("Using debug user %s.  Override with --email" % email)
		server = rpc_server_class(
				options.server,
				lambda: (email, "password"),
				host_override=options.host,
				extra_headers={"Cookie": 'dev_appserver_login="%s:False"' % email},
				save_cookies=options.save_cookies)
		# Don't try to talk to ClientLogin.
		server.authenticated = True
		return server

	return rpc_server_class(options.server, GetUserCredentials,
		host_override=options.host, save_cookies=options.save_cookies)


def EncodeMultipartFormData(fields, files):
	"""Encode form fields for multipart/form-data.

	Args:
		fields: A sequence of (name, value) elements for regular form fields.
		files: A sequence of (name, filename, value) elements for data to be
					uploaded as files.
	Returns:
		(content_type, body) ready for httplib.HTTP instance.

	Source:
		http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/146306
	"""
	BOUNDARY = '-M-A-G-I-C---B-O-U-N-D-A-R-Y-'
	CRLF = '\r\n'
	lines = []
	for (key, value) in fields:
		typecheck(key, str)
		typecheck(value, str)
		lines.append('--' + BOUNDARY)
		lines.append('Content-Disposition: form-data; name="%s"' % key)
		lines.append('')
		lines.append(value)
	for (key, filename, value) in files:
		typecheck(key, str)
		typecheck(filename, str)
		typecheck(value, str)
		lines.append('--' + BOUNDARY)
		lines.append('Content-Disposition: form-data; name="%s"; filename="%s"' % (key, filename))
		lines.append('Content-Type: %s' % GetContentType(filename))
		lines.append('')
		lines.append(value)
	lines.append('--' + BOUNDARY + '--')
	lines.append('')
	body = CRLF.join(lines)
	content_type = 'multipart/form-data; boundary=%s' % BOUNDARY
	return content_type, body


def GetContentType(filename):
	"""Helper to guess the content-type from the filename."""
	return mimetypes.guess_type(filename)[0] or 'application/octet-stream'


# Use a shell for subcommands on Windows to get a PATH search.
use_shell = sys.platform.startswith("win")

def RunShellWithReturnCode(command, print_output=False,
		universal_newlines=True, env=os.environ):
	"""Executes a command and returns the output from stdout and the return code.

	Args:
		command: Command to execute.
		print_output: If True, the output is printed to stdout.
			If False, both stdout and stderr are ignored.
		universal_newlines: Use universal_newlines flag (default: True).

	Returns:
		Tuple (output, return code)
	"""
	logging.info("Running %s", command)
	p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
		shell=use_shell, universal_newlines=universal_newlines, env=env)
	if print_output:
		output_array = []
		while True:
			line = p.stdout.readline()
			if not line:
				break
			print line.strip("\n")
			output_array.append(line)
		output = "".join(output_array)
	else:
		output = p.stdout.read()
	p.wait()
	errout = p.stderr.read()
	if print_output and errout:
		print >>sys.stderr, errout
	p.stdout.close()
	p.stderr.close()
	return output, p.returncode


def RunShell(command, silent_ok=False, universal_newlines=True,
		print_output=False, env=os.environ):
	data, retcode = RunShellWithReturnCode(command, print_output, universal_newlines, env)
	if retcode:
		ErrorExit("Got error status from %s:\n%s" % (command, data))
	if not silent_ok and not data:
		ErrorExit("No output from %s" % command)
	return data


class VersionControlSystem(object):
	"""Abstract base class providing an interface to the VCS."""

	def __init__(self, options):
		"""Constructor.

		Args:
			options: Command line options.
		"""
		self.options = options

	def GenerateDiff(self, args):
		"""Return the current diff as a string.

		Args:
			args: Extra arguments to pass to the diff command.
		"""
		raise NotImplementedError(
				"abstract method -- subclass %s must override" % self.__class__)

	def GetUnknownFiles(self):
		"""Return a list of files unknown to the VCS."""
		raise NotImplementedError(
				"abstract method -- subclass %s must override" % self.__class__)

	def CheckForUnknownFiles(self):
		"""Show an "are you sure?" prompt if there are unknown files."""
		unknown_files = self.GetUnknownFiles()
		if unknown_files:
			print "The following files are not added to version control:"
			for line in unknown_files:
				print line
			prompt = "Are you sure to continue?(y/N) "
			answer = raw_input(prompt).strip()
			if answer != "y":
				ErrorExit("User aborted")

	def GetBaseFile(self, filename):
		"""Get the content of the upstream version of a file.

		Returns:
			A tuple (base_content, new_content, is_binary, status)
				base_content: The contents of the base file.
				new_content: For text files, this is empty.  For binary files, this is
					the contents of the new file, since the diff output won't contain
					information to reconstruct the current file.
				is_binary: True iff the file is binary.
				status: The status of the file.
		"""

		raise NotImplementedError(
				"abstract method -- subclass %s must override" % self.__class__)


	def GetBaseFiles(self, diff):
		"""Helper that calls GetBase file for each file in the patch.

		Returns:
			A dictionary that maps from filename to GetBaseFile's tuple.  Filenames
			are retrieved based on lines that start with "Index:" or
			"Property changes on:".
		"""
		files = {}
		for line in diff.splitlines(True):
			if line.startswith('Index:') or line.startswith('Property changes on:'):
				unused, filename = line.split(':', 1)
				# On Windows if a file has property changes its filename uses '\'
				# instead of '/'.
				filename = to_slash(filename.strip())
				files[filename] = self.GetBaseFile(filename)
		return files


	def UploadBaseFiles(self, issue, rpc_server, patch_list, patchset, options,
											files):
		"""Uploads the base files (and if necessary, the current ones as well)."""

		def UploadFile(filename, file_id, content, is_binary, status, is_base):
			"""Uploads a file to the server."""
			set_status("uploading " + filename)
			file_too_large = False
			if is_base:
				type = "base"
			else:
				type = "current"
			if len(content) > MAX_UPLOAD_SIZE:
				print ("Not uploading the %s file for %s because it's too large." %
							(type, filename))
				file_too_large = True
				content = ""
			checksum = md5(content).hexdigest()
			if options.verbose > 0 and not file_too_large:
				print "Uploading %s file for %s" % (type, filename)
			url = "/%d/upload_content/%d/%d" % (int(issue), int(patchset), file_id)
			form_fields = [
				("filename", filename),
				("status", status),
				("checksum", checksum),
				("is_binary", str(is_binary)),
				("is_current", str(not is_base)),
			]
			if file_too_large:
				form_fields.append(("file_too_large", "1"))
			if options.email:
				form_fields.append(("user", options.email))
			ctype, body = EncodeMultipartFormData(form_fields, [("data", filename, content)])
			response_body = rpc_server.Send(url, body, content_type=ctype)
			if not response_body.startswith("OK"):
				StatusUpdate("  --> %s" % response_body)
				sys.exit(1)

		# Don't want to spawn too many threads, nor do we want to
		# hit Rietveld too hard, or it will start serving 500 errors.
		# When 8 works, it's no better than 4, and sometimes 8 is
		# too many for Rietveld to handle.
		MAX_PARALLEL_UPLOADS = 4

		sema = threading.BoundedSemaphore(MAX_PARALLEL_UPLOADS)
		upload_threads = []
		finished_upload_threads = []
		
		class UploadFileThread(threading.Thread):
			def __init__(self, args):
				threading.Thread.__init__(self)
				self.args = args
			def run(self):
				UploadFile(*self.args)
				finished_upload_threads.append(self)
				sema.release()

		def StartUploadFile(*args):
			sema.acquire()
			while len(finished_upload_threads) > 0:
				t = finished_upload_threads.pop()
				upload_threads.remove(t)
				t.join()
			t = UploadFileThread(args)
			upload_threads.append(t)
			t.start()

		def WaitForUploads():			
			for t in upload_threads:
				t.join()

		patches = dict()
		[patches.setdefault(v, k) for k, v in patch_list]
		for filename in patches.keys():
			base_content, new_content, is_binary, status = files[filename]
			file_id_str = patches.get(filename)
			if file_id_str.find("nobase") != -1:
				base_content = None
				file_id_str = file_id_str[file_id_str.rfind("_") + 1:]
			file_id = int(file_id_str)
			if base_content != None:
				StartUploadFile(filename, file_id, base_content, is_binary, status, True)
			if new_content != None:
				StartUploadFile(filename, file_id, new_content, is_binary, status, False)
		WaitForUploads()

	def IsImage(self, filename):
		"""Returns true if the filename has an image extension."""
		mimetype =  mimetypes.guess_type(filename)[0]
		if not mimetype:
			return False
		return mimetype.startswith("image/")

	def IsBinary(self, filename):
		"""Returns true if the guessed mimetyped isnt't in text group."""
		mimetype = mimetypes.guess_type(filename)[0]
		if not mimetype:
			return False  # e.g. README, "real" binaries usually have an extension
		# special case for text files which don't start with text/
		if mimetype in TEXT_MIMETYPES:
			return False
		return not mimetype.startswith("text/")


class FakeMercurialUI(object):
	def __init__(self):
		self.quiet = True
		self.output = ''
	
	def write(self, *args, **opts):
		self.output += ' '.join(args)
	def copy(self):
		return self
	def status(self, *args, **opts):
		pass

	def formatter(self, topic, opts):
		from mercurial.formatter import plainformatter
		return plainformatter(self, topic, opts)
	
	def readconfig(self, *args, **opts):
		pass
	def expandpath(self, *args, **opts):
		return global_ui.expandpath(*args, **opts)
	def configitems(self, *args, **opts):
		return global_ui.configitems(*args, **opts)
	def config(self, *args, **opts):
		return global_ui.config(*args, **opts)

use_hg_shell = False	# set to True to shell out to hg always; slower

class MercurialVCS(VersionControlSystem):
	"""Implementation of the VersionControlSystem interface for Mercurial."""

	def __init__(self, options, ui, repo):
		super(MercurialVCS, self).__init__(options)
		self.ui = ui
		self.repo = repo
		self.status = None
		# Absolute path to repository (we can be in a subdir)
		self.repo_dir = os.path.normpath(repo.root)
		# Compute the subdir
		cwd = os.path.normpath(os.getcwd())
		assert cwd.startswith(self.repo_dir)
		self.subdir = cwd[len(self.repo_dir):].lstrip(r"\/")
		if self.options.revision:
			self.base_rev = self.options.revision
		else:
			mqparent, err = RunShellWithReturnCode(['hg', 'log', '--rev', 'qparent', '--template={node}'])
			if not err and mqparent != "":
				self.base_rev = mqparent
			else:
				out = RunShell(["hg", "parents", "-q"], silent_ok=True).strip()
				if not out:
					# No revisions; use 0 to mean a repository with nothing.
					out = "0:0"
				self.base_rev = out.split(':')[1].strip()
	def _GetRelPath(self, filename):
		"""Get relative path of a file according to the current directory,
		given its logical path in the repo."""
		assert filename.startswith(self.subdir), (filename, self.subdir)
		return filename[len(self.subdir):].lstrip(r"\/")

	def GenerateDiff(self, extra_args):
		# If no file specified, restrict to the current subdir
		extra_args = extra_args or ["."]
		cmd = ["hg", "diff", "--git", "-r", self.base_rev] + extra_args
		data = RunShell(cmd, silent_ok=True)
		svndiff = []
		filecount = 0
		for line in data.splitlines():
			m = re.match("diff --git a/(\S+) b/(\S+)", line)
			if m:
				# Modify line to make it look like as it comes from svn diff.
				# With this modification no changes on the server side are required
				# to make upload.py work with Mercurial repos.
				# NOTE: for proper handling of moved/copied files, we have to use
				# the second filename.
				filename = m.group(2)
				svndiff.append("Index: %s" % filename)
				svndiff.append("=" * 67)
				filecount += 1
				logging.info(line)
			else:
				svndiff.append(line)
		if not filecount:
			ErrorExit("No valid patches found in output from hg diff")
		return "\n".join(svndiff) + "\n"

	def GetUnknownFiles(self):
		"""Return a list of files unknown to the VCS."""
		args = []
		status = RunShell(["hg", "status", "--rev", self.base_rev, "-u", "."],
				silent_ok=True)
		unknown_files = []
		for line in status.splitlines():
			st, fn = line.split(" ", 1)
			if st == "?":
				unknown_files.append(fn)
		return unknown_files

	def get_hg_status(self, rev, path):
		# We'd like to use 'hg status -C path', but that is buggy
		# (see http://mercurial.selenic.com/bts/issue3023).
		# Instead, run 'hg status -C' without a path
		# and skim the output for the path we want.
		if self.status is None:
			if use_hg_shell:
				out = RunShell(["hg", "status", "-C", "--rev", rev])
			else:
				fui = FakeMercurialUI()
				ret = hg_commands.status(fui, self.repo, *[], **{'rev': [rev], 'copies': True})
				if ret:
					raise hg_util.Abort(ret)
				out = fui.output
			self.status = out.splitlines()
		for i in range(len(self.status)):
			# line is
			#	A path
			#	M path
			# etc
			line = to_slash(self.status[i])
			if line[2:] == path:
				if i+1 < len(self.status) and self.status[i+1][:2] == '  ':
					return self.status[i:i+2]
				return self.status[i:i+1]
		raise hg_util.Abort("no status for " + path)
	
	def GetBaseFile(self, filename):
		set_status("inspecting " + filename)
		# "hg status" and "hg cat" both take a path relative to the current subdir
		# rather than to the repo root, but "hg diff" has given us the full path
		# to the repo root.
		base_content = ""
		new_content = None
		is_binary = False
		oldrelpath = relpath = self._GetRelPath(filename)
		out = self.get_hg_status(self.base_rev, relpath)
		status, what = out[0].split(' ', 1)
		if len(out) > 1 and status == "A" and what == relpath:
			oldrelpath = out[1].strip()
			status = "M"
		if ":" in self.base_rev:
			base_rev = self.base_rev.split(":", 1)[0]
		else:
			base_rev = self.base_rev
		if status != "A":
			if use_hg_shell:
				base_content = RunShell(["hg", "cat", "-r", base_rev, oldrelpath], silent_ok=True)
			else:
				base_content = str(self.repo[base_rev][oldrelpath].data())
			is_binary = "\0" in base_content  # Mercurial's heuristic
		if status != "R":
			new_content = open(relpath, "rb").read()
			is_binary = is_binary or "\0" in new_content
		if is_binary and base_content and use_hg_shell:
			# Fetch again without converting newlines
			base_content = RunShell(["hg", "cat", "-r", base_rev, oldrelpath],
				silent_ok=True, universal_newlines=False)
		if not is_binary or not self.IsImage(relpath):
			new_content = None
		return base_content, new_content, is_binary, status


# NOTE: The SplitPatch function is duplicated in engine.py, keep them in sync.
def SplitPatch(data):
	"""Splits a patch into separate pieces for each file.

	Args:
		data: A string containing the output of svn diff.

	Returns:
		A list of 2-tuple (filename, text) where text is the svn diff output
			pertaining to filename.
	"""
	patches = []
	filename = None
	diff = []
	for line in data.splitlines(True):
		new_filename = None
		if line.startswith('Index:'):
			unused, new_filename = line.split(':', 1)
			new_filename = new_filename.strip()
		elif line.startswith('Property changes on:'):
			unused, temp_filename = line.split(':', 1)
			# When a file is modified, paths use '/' between directories, however
			# when a property is modified '\' is used on Windows.  Make them the same
			# otherwise the file shows up twice.
			temp_filename = to_slash(temp_filename.strip())
			if temp_filename != filename:
				# File has property changes but no modifications, create a new diff.
				new_filename = temp_filename
		if new_filename:
			if filename and diff:
				patches.append((filename, ''.join(diff)))
			filename = new_filename
			diff = [line]
			continue
		if diff is not None:
			diff.append(line)
	if filename and diff:
		patches.append((filename, ''.join(diff)))
	return patches


def UploadSeparatePatches(issue, rpc_server, patchset, data, options):
	"""Uploads a separate patch for each file in the diff output.

	Returns a list of [patch_key, filename] for each file.
	"""
	patches = SplitPatch(data)
	rv = []
	for patch in patches:
		set_status("uploading patch for " + patch[0])
		if len(patch[1]) > MAX_UPLOAD_SIZE:
			print ("Not uploading the patch for " + patch[0] +
				" because the file is too large.")
			continue
		form_fields = [("filename", patch[0])]
		if not options.download_base:
			form_fields.append(("content_upload", "1"))
		files = [("data", "data.diff", patch[1])]
		ctype, body = EncodeMultipartFormData(form_fields, files)
		url = "/%d/upload_patch/%d" % (int(issue), int(patchset))
		print "Uploading patch for " + patch[0]
		response_body = rpc_server.Send(url, body, content_type=ctype)
		lines = response_body.splitlines()
		if not lines or lines[0] != "OK":
			StatusUpdate("  --> %s" % response_body)
			sys.exit(1)
		rv.append([lines[1], patch[0]])
	return rv
