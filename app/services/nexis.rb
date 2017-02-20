require "watir"
require "csv"

class Nexis
  attr_accessor :browser, :csv_writer, :input_data

  def initialize
    @browser = Watir::Browser.new
    @csv_writer = CSV.open("public/output.csv", "ab")
    @input_data = CSV.read("public/input.csv")
  end

  def call
    begin
      login
      input_data[0..29].each do |input|
        full_name = input[1]
        full_name = full_name[0..full_name.index("&")-1] if full_name.include? "&"
        first_name = full_name.match(" ").post_match.split(" ").first
        last_name = full_name.match(" ").pre_match

        params = {
          address: input[0],
          first_name: first_name,
          last_name: last_name,
          city: input[2],
          zip: input[3]
        }
        search params

        if browser.span(id: "spanNames1_0").exists?
          click_report
          get_data params
        else
          csv_writer << [params[:address], params[:first_name], params[:last_name], params[:city], params[:zip], "NOT FOUND"]
        end

        sleep(300)
      end
    rescue Exception => e
      byebug
    end

    csv_writer.close
    close_browser
  end

  def login
    browser.goto "https://www.nexis.com/auth/signoff.do"
    browser.text_field(name: "webId").set "billytran"
    browser.text_field(name: "password").set "mortgage179"
    browser.button(name: "signin").click
  end

  def search(params)
    browser.goto "https://www.nexis.com/search/flap.do?flapID=publicrecords"
    sleep 1
    frame_url = browser.frameset.attribute_value("onload")[25..-2]

    browser.goto frame_url
    browser.a(id: "MainContent_formSubmit_clearFormLink").click
    browser.text_field(id: "MainContent_FirstName").set params[:first_name]
    browser.text_field(id: "MainContent_LastName").set params[:last_name]
    browser.text_field(id: "MainContent_Address1").set params[:address]
    browser.text_field(id: "MainContent_City").set params[:city]
    browser.text_field(id: "MainContent_Zip5").set params[:zip]
    browser.button(id: "MainContent_formSubmit_searchButton").click
    sleep 1

    redirect_url = browser.url
    browser.goto URI.unescape(redirect_url[redirect_url.index("url=")+4..-1])
    sleep 1
  end

  def click_report
    browser.span(id: "spanNames1_0").a.click
    sleep 1

    redirect_url = browser.url
    browser.goto URI.unescape(redirect_url[redirect_url.index("url=")+4..-1])
    sleep 1
  end

  def get_data(params)
    emails = []
    phones = []

    email_section = browser.div(id: "SubjectSummary_EXPSEC_SubSum").text
    emails = email_section[email_section.index("E-Mail Sources")..-1].split("\n")[1..-1] if email_section.include? "E-Mail Sources"

    phone_section = browser.divs(class: "reportSection").select{|section| section.text.include? "Cellular & Alternate Phones"}.first
    if phone_section && phone_section.text.include?("0 record") == false
      phones = browser.div(id: "PhonesPluses_EXPSEC_PhonPlus").trs.select{|tr| tr.text.include? "Phone Number"}.map{|tr| tr.tds[1].text}
    end

    csv_writer << [params[:address], params[:first_name], params[:last_name], params[:city], params[:zip], phones.join(","), emails.join(",")]
  end

  def close_browser
    browser.quit
  end
end
