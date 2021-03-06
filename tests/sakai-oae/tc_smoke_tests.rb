#!/usr/bin/env ruby
# coding: UTF-8
# 
# == Synopsis
#
# Academic Smoke tests. Shallowly tests a broad range of features. This script will
# eventually be deprecated in favor of the more robust ts_smoke_tests.rb test suite.
# 
# Author: Abe Heward (aheward@rSmart.com)
$: << File.expand_path(File.dirname(__FILE__) + "/../../lib/")
gem "test-unit"
["test/unit", "watir-webdriver", "ci/reporter/rake/test_unit_loader",
  "../../config/OAE/config.rb", "utilities", "sakai-OAE/app_functions",
  "sakai-OAE/page_elements" ].each { |item| require item }

class TestSmokeTests < Test::Unit::TestCase
  
  include Utilities

  def setup
    
    # Get the test configuration data
    @config = AutoConfig.new
    @browser = @config.browser
    # Test user information from directory.yml...
    @user1 = @config.directory['person5']['id']
    @pass1 = @config.directory['person5']['password']
    @user1_name = "#{@config.directory['person5']['firstname']} #{@config.directory['person5']['lastname']}"
    @user2 = @config.directory['person7']['id']
    @pass2 = @config.directory['person7']['password']
    @user2_name = "#{@config.directory['person7']['firstname']} #{@config.directory['person7']['lastname']}"
    @user3 = @config.directory['person2']['id']
    @pass3 = @config.directory['person2']['password']
    @user3_name = "#{@config.directory['person2']['firstname']} #{@config.directory['person2']['lastname']}"
    @user4 = @config.directory['person1']['id']
    @pass4 = @config.directory['person1']['password']
    @user4_name = "#{@config.directory['person1']['firstname']} #{@config.directory['person1']['lastname']}"
    @user5 = @config.directory['person6']['id']
    @pass5 = @config.directory['person6']['password']
    @user5_name = "#{@config.directory['person6']['firstname']} #{@config.directory['person6']['lastname']}"
    
    @sakai = SakaiOAE.new(@browser)
    
    # Test case variables...
    @message_subject = random_alphanums(32) + " " + random_alphanums(32)
    @message_body = random_multiline(250, 20, :string)
    
    @document_name = random_alphanums
    @document_description = random_alphanums(64)
    @tag1 = random_alphanums
    @tag2 = random_alphanums
    
    @page_text = random_multiline(100, 8, :string)
    
    @page1_title = random_alphanums
    @page2_title = random_alphanums
    @page3_title = random_alphanums
    @page4_title = random_alphanums
    
    @page1_text = random_multiline(100, 8, :string)
    
    @comment_text = random_multiline(70, 8)
    
    @course_info = {
      :title=>random_alphanums,
      :description=>random_string,
      :tags=>random_string
    }
    
    @new_document = {:name=>random_alphanums, :visible=>"Public", :pages=>"3"}
    @existing_document = {:name=>"Tests and Quizzes", :title=>"Existing Doc", :visible =>"Participants only" }
    
    # Profile test data...
    # Basic Information...
    @basic = { :given=>random_string, :family=>random_string, :preferred=>random_string, :tags=>random_string }
    # About Me...
    @about_me = random_multiline(50, 5, :ascii)
    @academic_interests = "test2"#random_multiline(50, 5, :ascii)
    @personal_interests = "test3"#random_multiline(50, 5, :ascii)
    # Online...
    @online = {:site=>"Twitter",:url=>"www.twitter.com"}
    # Contact Info...
    @contact_info = {:institution=>random_string, :department=>random_string, :title=>random_string, :email=>"bla@bla.com", :im=>random_string, :phone=>random_string, :mobile=>random_string, :fax=>random_string, :address=>random_string, :city=>random_string, :state=>random_string, :zip=>random_string, :country=>random_string}
    # Publications...
    @publication = {:main_title=>random_string,
      :main_author=>random_string,
      :co_authors=>random_string,
      :publisher=>random_string,
      :place=>random_string,
      :volume_title=>random_string,
      :volume_info=>random_string,
      :year=>"19#{rand(99)}",
      :number=>random_string,
      :series=>random_string,
      :url=>"http://www.#{random_nicelink}.com"
      }
    
    @permission_alert = %(Permissions changed\nThe permissions for "#{@new_document[:name]}" have been successfully changed)
    
    # This is a switch that makes sure the directory.yml file will be updated
    # with the new name info for User 1, after the profile info is changed.
    @save_new_name = 0
    
  end
  
  def teardown
    if @save_new_name==1
      File.open("#{File.dirname(__FILE__)}/../../config/OAE/directory.yml", "w+") { |out| YAML::dump(@config.directory, out) }
    end
    
    # Close the browser window
    @browser.close
  end

  def test_smoke_checks1_adding_contacts
    
    # User 1 adds other users to contacts...
    dash = @sakai.login(@user1, @pass1) 

    my_contacts = dash.my_contacts

    search = my_contacts.find_and_add_people

    search.search_for=@user2_name
    search.add_contact @user2_name
    
    # Invites the connection...
    search.invite
    search.search_for=@user3_name
    search.add_contact @user3_name
    search.invite
    search.search_for=@user4_name
    search.add_contact @user4_name
    search.invite
    
    # User 1 signs out...
    @sakai.sign_out
    
    # Other users log in and accept User 1's contact invite...
    dash = @sakai.login(@user3, @pass3)
    my_contacts = dash.my_contacts
    my_contacts.accept_connection @user1_name
    @sakai.sign_out
    dash = @sakai.login(@user4, @pass4)
    my_contacts = dash.my_contacts
    my_contacts.accept_connection @user1_name
    @sakai.sign_out
    dash = @sakai.login(@user2, @pass2)
    my_contacts = dash.my_contacts

    # TEST CASE: Verify there is a pending invitation from
    # the expected person
    assert my_contacts.pending_invites.include? @user1_name
    
    # User 2 accepts connection
    my_contacts.accept_connection @user1_name
    
  end

  def test_smoke_checks2_the_rest
    
    # User 2 logs in
    dash = @sakai.login(@user2, @pass2)
    
    # User 2 sends user 1 a message...
    inbox = dash.my_messages
    inbox.compose_message
    inbox.send_this_message_to=@user1_name # Bug here with names that contain "bad" chars.
    inbox.subject=@message_subject
    inbox.body=@message_body
    inbox.send_message
    
    # Grabbing the message date for later validation...
    @message_date = make_date(Time.now, "oae-message")
    
    # User 2 signs out...
    @sakai.sign_out
    
    # User 1 logs in...
    dash = @sakai.login(@user1, @pass1)
    
    # User 1 goes to My Messages and checks that expected messages are there
    inbox = dash.my_messages
    
    # TEST CASE: Inbox contains the message just sent by User 2
    assert_nothing_raised { inbox.open_message @message_subject }
    
    # TEST CASE: Message view shows expected items...
    assert_equal @user2_name, inbox.message_sender
    assert_equal @message_date, inbox.message_date
    assert_equal @message_body, inbox.message_body
    
    # User 1 creates a private document...
    inbox.add_content
    inbox.create_new_document
    inbox.name_document=@document_name
    inbox.document_description=@document_description
    inbox.who_can_see_document="Private"
    
    # User 1 adds tags to document
    inbox.tags_and_categories=@tag1
    inbox.tags_and_categories=@tag2
    inbox.add
    inbox.done_add_collected

    # User 1 views the document profile from My Library...
    my_library = inbox.my_library

    document = my_library.open_document @document_name
    
    # User 1 edits the text on the document
    document.edit_page
    document.set_content=@page_text
    document.save
    
    # User 1 adds 4 pages to the document
    document.add_page @page1_title
    document.add_page @page2_title
    document.add_page @page3_title
    document.add_page @page4_title
    
    # User 1 edits the text on one of the doc pages
    page1 = document.open_document @page1_title
    page1.edit_page
    page1.set_content=@page1_text
    
    # User 1 adds widgets to the pages (Gradebook, Assignments, Basic LTI, Test and Quizzes) 
    page1.insert_gradebook
    page1.save
    page2 = page1.open_document @page2_title
    page2.edit_page
    page2.insert_assignments
    page2.save
    page3 = page2.open_document @page3_title
    page3.edit_page
    page3.insert_tests_and_quizzes
    page3.save
    page4 = page3.open_document @page4_title
    page4.edit_page
    page4.insert_gradebook
    page4.insert_horizontal_line
    page4.insert_calendar
    page4.insert_jisc_content
    page4.save
    
    # User 1 removes one of the pages from the doc
    page4.delete_page @page4_title
    page4.delete
    
    # User 1 shares the document with user 2
    page4.permissions
    page4.share_with=@user2_name
    page4.share
    page4.save_and_close
    
    # User 1 signs out...
    @sakai.sign_out

    # User 2 logs in and checks to see if the document is in ‘My Library’
    dash = @sakai.login(@user2, @pass2)

    my_library = dash.my_library

    # TEST CASE: User 1's shared document exists in user 2's library
    assert my_library.documents.include? @document_name
    
    doc = my_library.open_document @document_name
    
    # User 2 Posts a comment on User 1's document
    doc.comment_text @comment_text
    doc.comment
    
    # TEST CASE: Comment posts as expected...
    assert_equal @comment_text, doc.last_comment[:message]

    # User 2 creates a new public course with the basic template...
    create_course = doc.create_a_course
    new_course_info = create_course.use_basic_template
    new_course_info.title=@course_info[:title]
    new_course_info.description=@course_info[:description]
    new_course_info.tags=@course_info[:tags]

    library = new_course_info.create_basic_course

    # User 2 creates a new area in the course...
    library.add_new_area
    library.new_doc_name=@new_document[:name]
    library.new_doc_permissions=@new_document[:visible]
    library.number_of_pages=@new_document[:pages]
    library.done_add
    
    # User 2 adds some content in the course...
    # ... Creates an area from an existing doc...
    library.add_new_area
    library.add_an_existing_document @existing_document
    
    # TEST CASE: New pages appear as expected
    assert library.public_pages.include? @new_document[:name]
    assert library.public_pages.include? @existing_document[:title]

    # User 2 changes permissions on the new doc area so that students can't see it...
    library.permissions_for_page @new_document[:name]
    library.select_specific_roles_only
    library.uncheck_students_can_see
    
    # TEST CASE: Permissions on an area can be edited and saved
    assert_nothing_raised { library.apply_permissions }
    
    # TEST CASE: Alert box text is as expected
    assert_equal @permissions_alert, library.notification

    # User 2 changes the permissions on the course to "Participants only"...
    library.settings
    library.can_be_discovered_by="Participants only"
    
    # TEST CASE: User 2 can update the Course settings
    assert_nothing_raised { library.apply_settings }
    
    # User 2 adds User 5 as a student to the course
    library.manage_participants
    library.add_by_search @user5_name
    library.apply_and_save
    
    # User 2 signs out
    @sakai.sign_out

    #Scenario 4 (Navigate through Messages, Library, Memberships, and Contacts)
    #Log in as user that has contacts, content and memberships
    
    # User 1 logs in
    dash = @sakai.sign_in(@user1, @pass1)

    # User 1 goes to My Library and checks that expected content is there...
    my_library = dash.my_library
    
    # TEST CASE: User 1 can still see document user 1 created...
    assert my_library.documents.include? @document_name
    
    # TEST CASE: User 2's document is NOT in User 1's library...
    assert_equal false, my_library.documents.include?(@new_document[:name])
    
    # User 1 reads User 2's comment on the document profile...
    document = my_library.open_document @document_name
    
    # TEST CASE: Comment is visible, as expected...
    assert_equal @comment_text, document.last_comment[:message]
    assert_equal @user2_name, document.last_comment[:poster]
    
    # User 1 goes to My Profile and edits fields...
    my_profile = document.my_profile
    my_profile.given_name=@basic[:given]
    my_profile.family_name=@basic[:family]
    # Need to store the new name info in the directory.yml file!
    @config.directory['person5']['firstname'] = @basic[:given]
    @config.directory['person5']['lastname'] = @basic[:family]
    @user1_name = "#{@basic[:given]} #{@basic[:family]}"
    @save_new_name=1
    my_profile.preferred_name=@basic[:preferred]
    my_profile.tags=@basic[:tags]
    my_profile.update
    
    # User 1 makes all profile information public
    my_profile.about_me_permissions
    my_profile.can_be_seen_by="Everyone"
    my_profile.close_notification
    my_profile.apply_permissions
    my_profile.contact_information_permissions
    my_profile.can_be_seen_by="Everyone"
    my_profile.close_notification
    my_profile.apply_permissions
    my_profile.publications_permissions
    my_profile.can_be_seen_by="Everyone"
    my_profile.close_notification
    my_profile.apply_permissions
    my_profile.online_permissions
    my_profile.can_be_seen_by="Everyone"
    my_profile.apply_permissions

    # User 1 adds information to all profile sections...
    about_me = my_profile.about_me
    about_me.about_Me=@about_me
    about_me.academic_interests=@academic_interests
    about_me.personal_interests=@personal_interests
    about_me.update
    online = about_me.online
    online.add_another_online
    online.site=@online[:site]
    online.url=@online[:url]
    online.update
    contact_info = online.contact_information
    contact_info.fill_out_form @contact_info
    contact_info.update
    publications = contact_info.publications
    publications.add_another_publication
    publications.fill_out_form @publication
    publications.update
    
    # User 1 goes to My Memberships to see what items are there...
    my_memberships = publications.my_memberships
    
    # TEST CASE: User 1 is not a member of User 2's course...
    assert_equal false, my_memberships.memberships.include?(@course_info[:title])
    
    search = my_memberships.explore_courses
    
    search.search_for=@course_info[:title]
    
    # TEST CASE: User 1 can't find User's 2's "Participants Only" course by searching...
    assert_equal false, search.results_list.include?(@course_info[:title])
    
    # User 1 goes to My Contacts and checks that expected Contacts are there
    my_contacts = search.my_contacts
    
    # TEST CASE: Contacts list contains the 3 expected users
    assert my_contacts.contacts.include? @user2_name
    assert my_contacts.contacts.include? @user3_name
    assert my_contacts.contacts.include? @user4_name
    
    # User 1 logs out
    @sakai.logout
    
    # User 5 logs in
    dash = @sakai.login(@user5, @pass5)
    
    # User 5 goes to My Memberships to see what's there...
    my_memberships = dash.my_memberships
    
    # TEST CASE: User 5 was added to User 2's created course...
    assert my_memberships.memberships.include? @course_info[:title]
    
    # User 5 opens the course...
    library = my_memberships.open_course @course_info[:title]
    
    # TEST CASE: The Existing Doc page is visible
    assert library.pages.include? @existing_document[:title]
    
    # TEST CASE: User 2's new doc is not visible to User 5, who is a student...
    assert_equal false, library.pages.include?(@new_document[:name])
    
    # User 5 searches for the document created by User 2 and only shared with User 1
    search = library.explore_content
    
    search.search_for=@document_name
    
    # TEST CASE: User 2's private document does NOT appear in search by User 5,
    # who doesn't have permission to view it...
    assert_equal false, search.results.include?(@document_name)

    # User 5 logs out
    login_page = @sakai.logout

    # Public user Explores people
    search = login_page.explore_people
    search.search_for=@user1_name
    
    # TEST CASE: User 1 comes up in search
    assert search.results.include? @user1_name
    
    # User 1's profile info can be read while logged out...
    basic_info = search.view_person @user1_name
    
    # TEST CASE: Public Profile displays Basic info as expected
    assert_equal @basic[:given], basic_info.basic_info_data["Given Name:"]
    assert_equal @basic[:family], basic_info.basic_info_data["Family Name:"]
    assert_equal @basic[:preferred], basic_info.basic_info_data["Preferred Name:"]

    # TEST CASE: Expected tag is included
    assert basic_info.tags_and_categories_list.include? @basic[:tags]
    
    about_me = basic_info.about_me
    
    # TEST CASE: About me data is as expected
    assert_equal @about_me, about_me.about_me_data["About Me:"]
    assert_equal @academic_interests, about_me.about_me_data["Academic interests:"]
    assert_equal @personal_interests, about_me.about_me_data["Personal Interests:"]
    
    online = about_me.online
 
    # TEST CASE: Online info is as expected
    assert_equal @online[:site], online.online_data["Site:1"]
    assert_equal @online[:url], online.online_data["URL:1"]
    
    contact_info = online.contact_information
    
    # Contact info is as expected
    assert contact_info.expected_contact_info? @contact_info
    
    publications = contact_info.publications
    
    # TEST CASE: Publications info is as expected
    assert publications.expected_publications_data?(@publication), "Publications:\n"+publications.publications_data.join("\n")
    
    library = publications.open_library "#{@basic[:given]}'s library"
    
    # TEST CASE: User 1's private document is not listed in the Library
    assert_equal false, library.results_list.include?(@document_name)
  
  end
  
end
