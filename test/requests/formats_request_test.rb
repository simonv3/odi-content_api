require_relative '../test_helper'
require "gds_api/test_helpers/asset_manager"

class FormatsRequestTest < GovUkContentApiTest
  include GdsApi::TestHelpers::AssetManager

  def setup
    super
    @tag1 = FactoryGirl.create(:tag, tag_id: 'crime')
    @tag2 = FactoryGirl.create(:tag, tag_id: 'crime/batman')
  end

  it "should work with answer_edition" do
    artefact = FactoryGirl.create(:my_artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    answer = FactoryGirl.create(:edition, slug: artefact.slug, body: 'Important batman information', panopticon_id: artefact.id, state: 'published')

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]

    expected_fields = ['description', 'alternative_title', 'body', 'need_extended_font']

    assert_has_expected_fields(fields, expected_fields)
    assert_equal "<p>Important batman information</p>\n", fields["body"]
  end

  it "should work with guide_edition" do
    artefact = FactoryGirl.create(:my_artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    guide_edition = FactoryGirl.create(:guide_edition_with_two_govspeak_parts, slug: artefact.slug,
                                panopticon_id: artefact.id, state: 'published')
    guide_edition.save!

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'description', 'parts']

    assert_has_expected_fields(fields, expected_fields)
    refute fields.has_key?('body')
    assert_equal "Some Part Title!", fields['parts'][0]['title']
    assert_equal "<p>This is some <strong>version</strong> text.</p>\n", fields['parts'][0]['body']
    assert_equal "#{public_web_url}/batman/part-one", fields['parts'][0]['web_url']
    assert_equal "part-one", fields['parts'][0]['slug']
  end

  it "should work with programme_edition" do
    artefact = FactoryGirl.create(:my_artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    programme_edition = FactoryGirl.create(:programme_edition, slug: artefact.slug,
                                panopticon_id: artefact.id, state: 'published')
    programme_edition.save!

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'description', 'parts']

    assert_has_expected_fields(fields, expected_fields)
    refute fields.has_key?('body')
    assert_equal "Overview", fields['parts'][0]['title']
    assert_equal "#{public_web_url}/batman/overview", fields['parts'][0]['web_url']
    assert_equal "overview", fields['parts'][0]['slug']
  end
  
  describe "person editions" do
    before :each do
      FactoryGirl.create(:tag, :tag_id => "team-member", :tag_type => 'person')
      @artefact = FactoryGirl.create(:my_artefact, slug: 'batman', kind: 'person', person: ['team-member'], owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end
    
    it "should work with basic person edtion" do
      honorific_prefix = 'Sir'
      honorific_suffix = 'PhD'
      affiliation = 'Stately Wayne Manor'
      description = '## Foo bar'
      role = 'BATMAN!'
      url = 'http://www.batman.com'
      telephone = '1213134242'
      email = 'bat@man.com'
      twitter = 'batman'
      linkedin = 'http://www.linkedin.com/batman'
      github = 'https://github.com/batman'
      
      video_edition = FactoryGirl.create(:person_edition, title: 'Bruce Wayne', panopticon_id: @artefact.id, slug: @artefact.slug,
                                         honorific_prefix: honorific_prefix, honorific_suffix: honorific_suffix,
                                         url: url, affiliation: affiliation, role: role, telephone: telephone,
                                         email: email, twitter: twitter, linkedin: linkedin, github: github,
                                         description: description, state: 'published')

      get '/batman.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = %w(honorific_prefix honorific_suffix affiliation description role url telephone email twitter linkedin github)

      assert_has_expected_fields(fields, expected_fields)
      assert_equal honorific_prefix, fields["honorific_prefix"]
      assert_equal honorific_suffix, fields["honorific_suffix"]
      assert_equal affiliation, fields["affiliation"]
      assert_equal "<h2>Foo bar</h2>\n", fields["description"]
      assert_equal role, fields["role"]
      assert_equal url, fields["url"]
      assert_equal telephone, fields["telephone"]
      assert_equal email, fields["email"]
      assert_equal linkedin, fields["linkedin"]
      assert_equal github, fields["github"]
    end
    
  end
  
  describe "timed item editions" do
    before :each do
      FactoryGirl.create(:tag, :tag_id => "time", :tag_type => 'timed_item')
      @artefact = FactoryGirl.create(:my_artefact, slug: 'timey-wimey', kind: 'timed_item', timed_item: ['time'], owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end

    it "should work with basic timed_item_edition" do
      content = '## Some content'
      end_date = 1.month.from_now.to_datetime
      
      timed_item_edition = FactoryGirl.create(:timed_item_edition, title: 'Timey Wimey', 
                                              panopticon_id: @artefact.id, slug: @artefact.slug,
                                              content: content, end_date: end_date, state: 'published')

      get '/timey-wimey.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]
      
      expected_fields = %w(content end_date)
      
      assert_has_expected_fields(fields, expected_fields)
      
      assert_equal "<h2>Some content</h2>\n", fields["content"]
      assert_equal end_date.to_s, fields["end_date"].to_s
    end
  end
  
  describe "article editions" do
    before :each do
      FactoryGirl.create(:tag, :tag_id => "news", :tag_type => 'article')
      @artefact = FactoryGirl.create(:my_artefact, slug: 'some-news', kind: 'article', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live', article: ['news'])
    end
    
    it "should work with basic article edition" do
      content = '## A title'
      url = 'http://www.example.com'
      media_enquiries_name = 'Dave'
      media_enquiries_email = 'dave@example.com'
      media_enquiries_telephone = '1212312321'
      
      article_edition = FactoryGirl.create(:article_edition, title: 'Here is the news', 
                                            panopticon_id: @artefact.id, slug: @artefact.slug,
                                            content: content, url: url, media_enquiries_name: media_enquiries_name,
                                            media_enquiries_email: media_enquiries_email, media_enquiries_telephone: media_enquiries_telephone,
                                            state: 'published')
                                            
      get '/some-news.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = %w(content url media_enquiries_name media_enquiries_email media_enquiries_telephone)
      
      assert_has_expected_fields(fields, expected_fields)
      
      assert_equal "<h2>A title</h2>\n", fields["content"]
      assert_equal media_enquiries_name, fields["media_enquiries_name"]
      assert_equal media_enquiries_email, fields["media_enquiries_email"]
      assert_equal media_enquiries_telephone, fields["media_enquiries_telephone"]
    end
  end
  
  describe "case study editions" do
    before :each do
      @artefact = FactoryGirl.create(:my_artefact, slug: 'case-study', kind: 'case_study', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end
    
    it "should work with basic case study edition" do
      content = '## A case title'
      url = 'http://www.example.com/case'
      media_enquiries_name = 'Casey Jones'
      media_enquiries_email = 'casey@example.com'
      media_enquiries_telephone = '342343534534'
      
      article_edition = FactoryGirl.create(:case_study_edition, title: 'Studying your cases', 
                                            panopticon_id: @artefact.id, slug: @artefact.slug,
                                            content: content, url: url, media_enquiries_name: media_enquiries_name,
                                            media_enquiries_email: media_enquiries_email, media_enquiries_telephone: media_enquiries_telephone,
                                            state: 'published')
                                            
      get '/case-study.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = %w(content url media_enquiries_name media_enquiries_email media_enquiries_telephone)
      
      assert_has_expected_fields(fields, expected_fields)
      
      assert_equal "<h2>A case title</h2>\n", fields["content"]
      assert_equal media_enquiries_name, fields["media_enquiries_name"]
      assert_equal media_enquiries_email, fields["media_enquiries_email"]
      assert_equal media_enquiries_telephone, fields["media_enquiries_telephone"]
    end
  end
  
  describe "FAQ editions" do
    before :each do
      @artefact = FactoryGirl.create(:my_artefact, slug: 'meaning-of-life', kind: 'faq', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end
    
    it "should work with basic FAQ edition" do
      content = "**42**"

      article_edition = FactoryGirl.create(:faq_edition, title: 'What is the meaning of life?', 
                                            panopticon_id: @artefact.id, slug: @artefact.slug,
                                            content: content, state: 'published')

      get '/meaning-of-life.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)
      
      expected_fields = %w(content)
      
      fields = parsed_response["details"]
      
      assert_has_expected_fields(fields, expected_fields)
      
      assert_equal "<p><strong>42</strong></p>\n", fields["content"]
    end
  end

  describe "Job editions" do
    before :each do
      @artefact = FactoryGirl.create(:my_artefact, slug: 'jobby-job', kind: 'job', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end
    
    it "should work with basic job edition" do
      location = 'The Moon'
      salary = '20p/decade'
      description = 'Live on the moon'
      closing_date = 1.month.from_now

      article_edition = FactoryGirl.create(:job_edition, title: 'The job of a lifetime', 
                                            panopticon_id: @artefact.id, slug: @artefact.slug,
                                            location: location, salary: salary,
                                            description: description, closing_date: closing_date,
                                            state: 'published')

      get '/jobby-job.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)
      
      expected_fields = %w(location salary description closing_date)
      
      fields = parsed_response["details"]
      
      assert_has_expected_fields(fields, expected_fields)
      
      assert_equal location, fields["location"]
      assert_equal salary, fields["salary"]
      assert_equal "<p>Live on the moon</p>\n", fields["description"]
      assert_equal closing_date.to_s, fields["closing_date"].to_s
    end
  end
  
  describe "organization editions" do
    before :each do
      FactoryGirl.create(:tag, :tag_id => "startup", :tag_type => 'organization')
      @artefact = FactoryGirl.create(:my_artefact, slug: 'widgets-inc', kind: 'organization', organization: ['startup'], owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end
    
    it "should work with basic organization edtion" do
      description  = 'A basic description'
      joined_at    = Date.today
      tagline      = "tagline"
      involvement  = "involvment"
      want_to_meet = "want to meet"
      case_study   = "001-002-003"
      url          = "http://bbc.co.uk"
      telephone    = "1234"
      email        = "hello@example.com"
      twitter      = "example"
      linkedin     = "http://linkedin.com/example"
      
      organization_edition = FactoryGirl.create(:organization_edition, title: 'Widgets Inc', panopticon_id: @artefact.id, slug: @artefact.slug,
                                                 description: description, joined_at: joined_at,
                                                 tagline: tagline, involvement: involvement, want_to_meet: want_to_meet, 
                                                 case_study: case_study, url: url, telephone: telephone, email: email, 
                                                 twitter: twitter, linkedin: linkedin, state: 'published')

      get '/widgets-inc.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = %w(description joined_at tagline involvement want_to_meet case_study url telephone email twitter linkedin)

      assert_has_expected_fields(fields, expected_fields)
      assert_equal joined_at.to_s, fields["joined_at"].to_s
      assert_equal tagline, fields["tagline"]
      assert_equal involvement, fields["involvement"]
      assert_equal "<p>A basic description</p>\n", fields["description"]
      assert_equal want_to_meet, fields["want_to_meet"]
      assert_equal case_study, fields["case_study"]
      assert_equal url, fields["url"]
      assert_equal telephone, fields["telephone"]
      assert_equal email, fields["email"]
      assert_equal linkedin, fields["linkedin"]
    end
    
  end
  
  describe "creative work editions" do
    before :each do
      @artefact = FactoryGirl.create(:my_artefact, slug: 'mona-lisa', kind: 'creative_work', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end   
    
    it "should work with basic creative_work_edition" do
      description = 'The Mona Lisa - what did you expect?'
      date_published = 1.month.ago.to_date

      creative_work_edition = FactoryGirl.create(:creative_work_edition, title: 'Mona Lisa', 
                                                  panopticon_id: @artefact.id, slug: @artefact.slug,
                                                  description: description, date_published: date_published,
                                                  state: 'published')

      get '/mona-lisa.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = %w(description date_published)

      assert_has_expected_fields(fields, expected_fields)  
      assert_equal "<p>The Mona Lisa - what did you expect?</p>\n", fields["description"]
      assert_equal date_published.to_s, fields["date_published"].to_s       
    end

    it "should contain artist information" do
      artist = FactoryGirl.create(:my_artefact, slug: 'banksy', kind: 'person', owning_app: 'publisher', state: 'live', name: 'Mr Banksy', person: ['writers'])
      person = FactoryGirl.create(:person_edition,
        title: artist.name,
        slug: artist.slug,
        panopticon_id: artist.id,
        state: 'published'
      )
      creative_work_edition = FactoryGirl.create(:creative_work_edition, title: 'Stencil Mona List',
                                            panopticon_id: @artefact.id, slug: @artefact.slug,
                                            description: "Banksy vs Mona", date_published: 1.month.ago.to_date,
                                            artist: "banksy", state: 'published')

      get '/mona-lisa.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?

      fields = parsed_response["details"]
      assert_equal fields["artist"]["name"], "Mr Banksy"
      assert_equal fields["artist"]["slug"], "banksy"
    end
  end
  
  describe "course editions" do
    before :each do
      @artefact = FactoryGirl.create(:my_artefact, slug: 'all-the-datas', kind: 'course', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end
    
    it "should work with basic course_edition" do
      description = "This is an awesome course"
      length = "5 days"

      course_edition = FactoryGirl.create(:course_edition, title: 'Mona Lisa', 
                                          panopticon_id: @artefact.id, slug: @artefact.slug,
                                          description: description, length: length,
                                          state: 'published')
      
      get '/all-the-datas.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = %w(description length)

      assert_has_expected_fields(fields, expected_fields)  
      assert_equal "<p>This is an awesome course</p>\n", fields["description"]
      assert_equal length, fields["length"]     
    end
    
  end
    
  describe "course instance editions" do
    before :each do
      @course_artefact = FactoryGirl.create(:my_artefact, slug: 'all-the-datas', kind: 'course', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')      
      @artefact = FactoryGirl.create(:my_artefact, slug: 'all-the-datas-2013-02-03', kind: 'course_instance', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end
    
    it "should work with basic course_edition" do
      course_title = "All the datas"
      date = 1.month.from_now
      location = "The ODI"
      price = "1 shiny penny"
      description = "Foo bar baz"
      trainers = ['ian', 'mike', 'stu']

      course_edition = FactoryGirl.create(:course_edition, title: course_title, 
                                          panopticon_id: @course_artefact.id, slug: @course_artefact.slug,
                                          description: 'description', length: 'length',
                                          state: 'published')
      course_instance_edition = FactoryGirl.create(:course_instance_edition, title: 'All the datas: 2013-02-03', 
                                          panopticon_id: @artefact.id, slug: @artefact.slug,
                                          course: @course_artefact.slug, date: date, location: location, 
                                          price: price, description: description, trainers: trainers,
                                          state: 'published')
      
      get '/all-the-datas-2013-02-03.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]
      
      expected_fields = %w(course date location price description trainers)

      assert_has_expected_fields(fields, expected_fields)  
      assert_equal "<p>Foo bar baz</p>\n", fields["description"]
      assert_equal @course_artefact.slug, fields["course"]     
      assert_equal course_title, fields["course_title"]     
      assert_equal date.to_s, Time.zone.parse(fields["date"]).to_s
      assert_equal location, fields["location"] 
      assert_equal price, fields["price"]
      assert_equal trainers, fields["trainers"]   
    end
  end
  
  describe "event editons" do
    before :each do
      FactoryGirl.create(:tag, :tag_id => "lunchtime-lecture", :tag_type => 'event')
      @artefact = FactoryGirl.create(:my_artefact, slug: 'lunchtime-lecture', kind: 'event', event: ['lunchtime-lecture'], owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end
    
    it "should work with basic event_edition" do
      start_date = 1.day.from_now
      end_date = 2.days.from_now
      location = "The ODI"
      description = "Event stuff goes here"
      booking_url = "http://example.com"
      hashtag = "foobar"
      
      event_edition = FactoryGirl.create(:event_edition, title: 'Lunchtime lecture', 
                                          panopticon_id: @artefact.id, slug: @artefact.slug,
                                          start_date: start_date, end_date: end_date, location: location, 
                                          description: description, booking_url: booking_url, hashtag: hashtag,
                                          state: 'published')

      get '/lunchtime-lecture.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = %w(start_date end_date location description booking_url hashtag)

      assert_has_expected_fields(fields, expected_fields)  
      assert_equal "<p>Event stuff goes here</p>\n", fields["description"]    
      assert_equal start_date.to_s, Time.zone.parse(fields["start_date"]).to_s
      assert_equal end_date.to_s, Time.zone.parse(fields["end_date"]).to_s
      assert_equal booking_url, fields["booking_url"] 
      assert_equal hashtag, fields["hashtag"]
    end

  end
  
  describe "node editons" do
    before :each do
      @artefact = FactoryGirl.create(:my_artefact, slug: 'birmingham', kind: 'node', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end
    
    it "should work with basic node_edition" do
      level = "country"
      beta = false
      join_date = Date.new(2013,10,2)
      region = "GB"
      area = "Birmingham"
      location = [51.43242,-1.534543543]
      description = "This is a really long description"
      telephone = "123456677788"
      twitter = "example"
      linkedin = "http://linkedin.com/example"
      
      node_edition = FactoryGirl.create(:node_edition, title: 'Birmingham', 
                                          panopticon_id: @artefact.id, slug: @artefact.slug,
                                          beta: beta, join_date: join_date, area: area,
                                          level: level, region: region, location: location, 
                                          description: description, telephone: telephone, twitter: twitter,
                                          linkedin: linkedin, state: 'published')

      get '/birmingham.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = %w(level region location description telephone twitter linkedin)

      assert_has_expected_fields(fields, expected_fields)  
      assert_equal "<p>This is a really long description</p>\n", fields["description"]    
      assert_equal level, fields["level"]
      assert_equal beta, fields["beta"]
      assert_equal region, fields["region"] 
      assert_equal area, fields["area"] 
      assert_equal location, fields["location"]
      assert_equal telephone, fields["telephone"]
      assert_equal twitter, fields["twitter"]
      assert_equal linkedin, fields["linkedin"]
      assert_equal join_date, Date.parse(fields["join_date"])
    end

  end

  describe "video editions" do
    before :each do
      @artefact = FactoryGirl.create(:my_artefact, slug: 'batman', kind: 'video', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end

    it "should work with basic video_edition" do
      video_edition = FactoryGirl.create(:video_edition, title: 'Video killed the radio star', panopticon_id: @artefact.id, slug: @artefact.slug,
                                         video_summary: 'I am a video summary', video_url: 'http://somevideourl.com',
                                         body: "Video description\n------", state: 'published')

      get '/batman.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = %w(alternative_title description video_url video_summary body)

      assert_has_expected_fields(fields, expected_fields)
      assert_equal "I am a video summary", fields["video_summary"]
      assert_equal "http://somevideourl.com", fields["video_url"]
      assert_equal "<h2>Video description</h2>\n", fields["body"]
    end

    describe "loading the caption_file from asset-manager" do
      it "should include the caption_file details" do
        edition = FactoryGirl.create(:video_edition, :slug => @artefact.slug,
                                     :panopticon_id => @artefact.id, :state => "published",
                                     :caption_file_id => "512c9019686c82191d000001")

        asset_manager_has_an_asset("512c9019686c82191d000001", {
          "id" => "http://asset-manager.#{ENV["GOVUK_APP_DOMAIN"]}/assets/512c9019686c82191d000001",
          "name" => "captions-file.xml",
          "content_type" => "application/xml",
          "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/captions-file.xml",
          "state" => "clean",
        })

        get "/batman.json"
        assert last_response.ok?

        parsed_response = JSON.parse(last_response.body)
        caption_file_info = {
          "web_url"=>"https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/captions-file.xml",
          "versions"=>nil,
          "content_type"=>"application/xml",
          "title"=>nil, 
          "source"=>nil, 
          "description"=>nil, 
          "creator"=>nil, 
          "attribution"=>nil, 
          "subject"=>nil, 
          "license"=>nil, 
          "spatial"=>nil
        }
        assert_equal caption_file_info, parsed_response["details"]["caption_file"]
      end

      it "should gracefully handle failure to reach asset-manager" do
        edition = FactoryGirl.create(:video_edition, :slug => @artefact.slug,
                                     :panopticon_id => @artefact.id, :state => "published",
                                     :caption_file_id => "512c9019686c82191d000001")

        stub_request(:get, "http://asset-manager.#{ENV["GOVUK_APP_DOMAIN"]}/assets/512c9019686c82191d000001").to_return(:body => "Error", :status => 500)

        get '/batman.json'
        assert last_response.ok?

        parsed_response = JSON.parse(last_response.body)
        assert_base_artefact_fields(parsed_response)

        refute parsed_response["details"].has_key?("caption_file")
      end

      it "should not blow up with an type mismatch between the artefact and edition" do
        # This can happen when a format is being changed, and the draft edition is being preview
        edition = FactoryGirl.create(:answer_edition, :slug => @artefact.slug,
                                     :panopticon_id => @artefact.id, :state => "published")

        get '/batman.json'
        assert last_response.ok?
      end
    end
  end
  
  it "should work with simple smart-answers" do
    artefact = FactoryGirl.create(:my_artefact, :slug => 'the-bridge-of-death', :owning_app => 'publisher', :state => 'live')
    smart_answer = FactoryGirl.build(:simple_smart_answer_edition, :panopticon_id => artefact.id, :state => 'published',
                        :body => "STOP!\n-----\n\nHe who would cross the Bridge of Death  \nMust answer me  \nThese questions three  \nEre the other side he see.\n")

    n = smart_answer.nodes.build(:kind => 'question', :slug => 'what-is-your-name', :title => "What is your name?", :order => 1)
    n.options.build(:label => "Sir Lancelot of Camelot", :next_node => 'what-is-your-favorite-colour', :order => 1)
    n.options.build(:label => "Sir Galahad of Camelot", :next_node => 'what-is-your-favorite-colour', :order => 3)
    n.options.build(:label => "Sir Robin of Camelot", :next_node => 'what-is-the-capital-of-assyria', :order => 2)

    n = smart_answer.nodes.build(:kind => 'question', :slug => 'what-is-your-favorite-colour', :title => "What is your favorite colour?", :order => 3)
    n.options.build(:label => "Blue", :next_node => 'right-off-you-go')
    n.options.build(:label => "Blue... NO! YELLOOOOOOOOOOOOOOOOWWW!!!!", :next_node => 'arrrrrghhhh')

    n = smart_answer.nodes.build(:kind => 'question', :slug => 'what-is-the-capital-of-assyria', :title => "What is the capital of Assyria?", :order => 2)
    n.options.build(:label => "I don't know THAT!!", :next_node => 'arrrrrghhhh')

    n = smart_answer.nodes.build(:kind => 'outcome', :slug => 'right-off-you-go', :title => "Right, off you go.", :body => "Oh! Well, thank you.  Thank you very much", :order => 4)
    n = smart_answer.nodes.build(:kind => 'outcome', :slug => 'arrrrrghhhh', :title => "AAAAARRRRRRRRRRRRRRRRGGGGGHHH!!!!!!!", :order => 5)
    smart_answer.save!

    get '/the-bridge-of-death.json'
    assert_equal 200, last_response.status

    parsed_response = JSON.parse(last_response.body)
    assert_base_artefact_fields(parsed_response)
    details = parsed_response["details"]

    assert_has_expected_fields(details, %w(body smart_answer_nodes))
    assert_equal "<h2>STOP!</h2>\n\n<p>He who would cross the Bridge of Death<br />\nMust answer me<br />\nThese questions three<br />\nEre the other side he see.</p>", details["body"].strip

    nodes = details["smart_answer_nodes"]["nodes"]

    assert_equal ["What is your name?", "What is the capital of Assyria?", "What is your favorite colour?", "Right, off you go.", "AAAAARRRRRRRRRRRRRRRRGGGGGHHH!!!!!!!" ], nodes.map {|n| n["title"]}

    question1 = nodes[0]
    assert_equal "question", question1["kind"]
    assert_equal "what-is-your-name", question1["slug"]
    assert_equal ["Sir Lancelot of Camelot", "Sir Robin of Camelot", "Sir Galahad of Camelot"], question1["options"].map {|o| o["label"]}
    assert_equal ["sir-lancelot-of-camelot", "sir-robin-of-camelot", "sir-galahad-of-camelot"], question1["options"].map {|o| o["slug"]}
    assert_equal ["what-is-your-favorite-colour", "what-is-the-capital-of-assyria", "what-is-your-favorite-colour"], question1["options"].map {|o| o["next_node"]}

    outcome1 = nodes[3]
    assert_equal "outcome", outcome1["kind"]
    assert_equal "right-off-you-go", outcome1["slug"]
    assert_equal "<p>Oh! Well, thank you.  Thank you very much</p>", outcome1["body"].strip
  end
end
