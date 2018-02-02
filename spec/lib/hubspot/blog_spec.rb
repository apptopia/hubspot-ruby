require 'timecop'

describe Hubspot do
  let(:example_blog_hash) do
    VCR.use_cassette("blog_list", record: :none) do
      url = Hubspot::Connection.send(:generate_url, Hubspot::Blog::BLOG_LIST_PATH)
      resp = HTTParty.get(url, format: :json)
      resp.parsed_response["objects"].first
    end
  end
  let(:created_range_params) { { created__gt: false, created__range: (Time.now..Time.now + 2.years)  } }
  let(:logger) { mock('logger') }
  let(:blog_id) { 351076997 }

  before do
    Hubspot.configure(hapikey: "demo")
    Timecop.freeze(Time.utc(2014, 'Oct', 10))
  end

  after do
    Timecop.return
  end

  describe Hubspot::Blog do

    describe ".list" do
      cassette "blog_list"
      let(:blog_list) { Hubspot::Blog.list }

      it "should have a list of blogs" do
        blog_list.count.should be(1)
      end

      context 'with logger' do
        it 'logs request' do
          mock(logger).log(:get, 'https://api.hubapi.com/content/api/v2/blogs?hapikey=demo', anything, anything, anything){ true }
          Hubspot::Blog.list(logger: logger)
        end
      end
    end

    describe ".find_by_id" do
      cassette "blog_list"

      it "should have a list of blogs" do
        blog = Hubspot::Blog.find_by_id(blog_id)
        blog["id"].should eq(blog_id)
      end

      context 'with logger' do
        it 'logs request' do
          mock(logger).log(:get, "https://api.hubapi.com/content/api/v2/blogs/#{blog_id}?hapikey=demo", anything, anything, anything){ true }
          Hubspot::Blog.find_by_id(blog_id, logger: logger)
        end
      end
    end

    describe "#initialize" do
      subject{ Hubspot::Blog.new(example_blog_hash) }
      its(["name"]) { should == "API Demonstration Blog" }
      its(["id"])   { should == blog_id }
    end

    describe "#posts" do
      cassette "one_month_blog_posts_filter_state"
      let!(:blog) { Hubspot::Blog.new(example_blog_hash) }

      describe "can be filtered by state" do

        it "should filter the posts to published by default" do
          blog.posts.map{ |p| p['state'] }.uniq.should eq(['PUBLISHED'])
        end

        it "should validate the state is a valid one" do
          expect { blog.posts('invalid') }.to raise_error(Hubspot::InvalidParams)
        end

        it "should allow draft posts if specified" do
          blog.posts({ state: false }.merge(created_range_params)).length.should be > 0
        end
      end

      describe "can be ordered" do
        it "created at descending is default" do
          created_timestamps = blog.posts(created_range_params).map { |post| post['created'] }
          expect(created_timestamps.sort.reverse).to eq(created_timestamps)
        end

        it "by created ascending" do
          pending 'Not yet implemented on API side'
          created_timestamps = blog.posts({order_by: '+created'}.merge(created_range_params)).map { |post| post['created'] }
          expect(created_timestamps.sort).to eq(created_timestamps)
        end
      end

      it "can set a page size" do
        blog.posts({limit: 10}.merge(created_range_params)).length.should be(10)
      end

      context 'with logger' do
        it 'logs request' do
          mock(logger).log(:get, anything, anything, anything, anything){ true }
          blog.posts(logger: logger)
        end
      end
    end
  end

  describe Hubspot::BlogPost do
    cassette "blog_posts"
    let(:post_id) { 5425703961 }
    let(:post) { Hubspot::BlogPost.find_by_blog_post_id(post_id) }

    let(:example_blog_post) do
      VCR.use_cassette("one_month_blog_posts_filter_state", record: :none) do
        blog = Hubspot::Blog.new(example_blog_hash)
        blog.posts(created_range_params).first
      end
    end

    it "should have a created_at value specific method" do
      expect(example_blog_post.created_at).to eq(Time.at(example_blog_post['created'] / 1000))
    end

    context '#find_by_blog_post_id' do
      it "finds post" do
        expect(post['id']).to eq(post_id)
      end

      context 'with logger' do
        it 'logs request' do
          mock(logger).log(:get, anything, anything, anything, anything){ true }
          Hubspot::BlogPost.find_by_blog_post_id(post_id, logger: logger)
        end
      end
    end

    context 'containing a topic' do
      it "should return topic objects" do
        expect(post.topics.first.is_a?(Hubspot::Topic)).to be(true)
      end

      context 'with logger' do
        it 'logs requests' do
          mock(logger).log(:get, anything, anything, anything, anything){ true }
          post.topics(logger: logger)
        end
      end
    end
  end
end
