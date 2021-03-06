require 'minitest_helper'
require 'honyomi/query'

module Honyomi
  class TestQuery < MiniTest::Test
    def test_simple
      q = Query.new("aaa")
      assert_equal "aaa", q.page_query
      assert_equal nil, q.jump_page_no
    end

    def test_jump_page_no
      q = Query.new("111")
      assert_equal "page_no:111", q.page_query
      assert_equal 111, q.jump_page_no
      
      q = Query.new("111 123")
      assert_equal "page_no:111 page_no:123", q.page_query
      assert_equal 123, q.jump_page_no

      q = Query.new("aaa 222")
      assert_equal "aaa page_no:222", q.page_query
      assert_equal 222, q.jump_page_no
    end

    def test_phrase
      q = Query.new("aaa \"bbb ccc\" ddd")
      assert_equal "aaa \"bbb ccc\" ddd", q.page_query
    end

    def test_book
      q = Query.new("b:22 bbb")
      assert_equal "book:22 bbb", q.page_query
    end

    def test_book_title
      q = Query.new("t:\"aaa bbb\" ccc")
      assert_equal "book.title:@\"aaa bbb\" ccc", q.page_query
    end

    def test_page_no
      q = Query.new("p:11 t:\"aaa bbb\"")
      assert_equal "page_no:11 book.title:@\"aaa bbb\"", q.page_query
    end

    def test_and_or
      q = Query.new("aaa + bbb")
      assert_equal "aaa + bbb", q.page_query

      q = Query.new("aaa OR bbb")
      assert_equal "aaa OR bbb", q.page_query

      q = Query.new("aaa (\"ddd bbb\" OR t:CCC)")
      assert_equal "aaa (\"ddd bbb\" OR book.title:@CCC)", q.page_query
    end

    def test_bookmark_query
      q = Query.new("aaa")
      assert_equal "aaa", q.bookmark_query

      q = Query.new("aaa t:bbb")
      assert_equal "aaa page.book.title:@bbb", q.bookmark_query

      q = Query.new("aaa b:11")
      assert_equal "aaa page.book:11", q.bookmark_query

      q = Query.new("aaa p:12")
      assert_equal "aaa page.book.page_no:12", q.bookmark_query

      q = Query.new("aaa (\"ddd bbb\" OR t:CCC)")
      assert_equal "aaa (\"ddd bbb\" OR page.book.title:@CCC)", q.bookmark_query
    end

    def test_minus
      q = Query.new("aaa -book:10")
      assert_equal "aaa -page.book:10", q.bookmark_query
    end
  end
end
