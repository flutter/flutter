#!/usr/bin/ruby

require 'test/unit'
require 'open-uri'
require 'PrettyPatch'

# Note: internet connection is needed to run this test suite.

class PrettyPatch_test < Test::Unit::TestCase
    class Info
        TITLE = 0
        FILE = 1
        ADD = 2
        REMOVE = 3
        SHARED = 4
    end

    PATCHES = {
        20510 => ["Single change", 1, 1, 0, 2],
        20528 => ["No 'Index' or 'diff' in patch header", 1, 4, 3, 7],
        21151 => ["Leading '/' in the path of files", 4, 9, 1, 16],
        # Binary files use shared blocks, there are three in 30488.
        30488 => ["Quoted filenames in git diff", 23, 28, 25, 64 + 3],
        23920 => ["Mac line ending", 3, 3, 0, 5],
        39615 => ["Git signature", 2, 2, 0, 3],
        80852 => ["Changes one line plus ChangeLog", 2, 2, 1, 4],
        83127 => ["Only add stuff", 2, 2, 0, 3],
        85071 => ["Adds and removes from a file plus git signature", 2, 5, 3, 9],
        106368 => ["Images with git delta binary patch", 69, 8, 23, 10],
    }

    def get_patch_uri(id)
        "https://bugs.webkit.org/attachment.cgi?id=" + id.to_s
    end

    def get_patch(id)
        result = nil
        patch_uri = get_patch_uri(id)
        begin
            result = open(patch_uri) { |f| result = f.read }
        rescue => exception
            assert(false, "Fail to get patch " + patch_uri)
        end
        result
    end

    def check_one_patch(id, info)
        patch = get_patch(id)
        description = get_patch_uri(id)
        description +=  " (" + info[Info::TITLE] + ")" unless info[Info::TITLE].nil?
        puts "Testing " + description
        pretty = nil
        assert_nothing_raised("Crash while prettifying " + description) {
            pretty = PrettyPatch.prettify(patch)
        }
        assert(pretty, "Empty result while prettifying " + description)
        assert_equal(info[Info::FILE], $last_prettify_file_count, "Wrong number of files changed in " + description)
        assert_equal(info[Info::ADD], $last_prettify_part_count["add"], "Wrong number of 'add' parts in " + description)
        assert_equal(info[Info::REMOVE], $last_prettify_part_count["remove"], "Wrong number of 'remove' parts in " + description)
        assert_equal(info[Info::SHARED], $last_prettify_part_count["shared"], "Wrong number of 'shared' parts in " + description)
        assert_equal(0, $last_prettify_part_count["binary"], "Wrong number of 'binary' parts in " + description)
        assert_equal(0, $last_prettify_part_count["extract-error"], "Wrong number of 'extract-error' parts in " + description)
        return pretty
    end

    def test_patches
        PATCHES.each { |id, info| check_one_patch(id, info) }
    end

    def test_images_without_checksum
        pretty = check_one_patch(144064, ["Images without checksums", 10, 5, 4, 8])
        matches = pretty.match("INVALID: Image lacks a checksum.")
        # FIXME: This should match, but there's a bug when running the tests where the image data
        # doesn't get properly written out to the temp files, so there is no image and we don't print
        # the warning that the image is missing its checksum.
        assert(!matches, "Should have invalid checksums")
        # FIXME: This should only have 4 invalid images, but due to the above tempfile issue, there are 0.
        assert_equal(0, pretty.scan(/INVALID\: Image lacks a checksum\./).size)
    end

    def test_new_image
        pretty = check_one_patch(145881, ["New image", 19, 36, 19, 56])
        matches = pretty.match("INVALID: Image lacks a checksum.")
        assert(!matches, "Should not have invalid checksums")
    end

    def test_images_correctly_without_checksum_git
        pretty = check_one_patch(101620, ["Images correctly without checksums git", 7, 15, 10, 26])
        matches = pretty.match("INVALID: Image lacks a checksum.")
        assert(!matches, "Png should lack a checksum without an error.")
    end

    def test_images_correctly_without_checksum_svn
        pretty = check_one_patch(31202, ["Images correctly without checksums svn", 4, 4, 1, 4])
        matches = pretty.match("INVALID: Image lacks a checksum.")
        assert(!matches, "Png should lack a checksum without an error.")
    end

end
