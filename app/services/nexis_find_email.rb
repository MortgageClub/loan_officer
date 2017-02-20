require "watir"
require "csv"

class NexisFindEmail
  attr_accessor :browser, :csv_writer, :input_data

  def initialize
    @browser = Watir::Browser.new
    @browser.window.maximize
    @csv_writer = CSV.open("public/output_nexis_1.csv", "ab")
    @input_data = CSV.read("public/dg-contacts.csv", encoding: "ISO-8859-1")
  end

  def call
    begin
      login
      input_data.each do |input|
        phone = input[5].to_s.strip! == "-" ? input[6].to_s : input[5].to_s
        phone = remove_format_phone(phone)
        ap phone

        params = {
          first_name: input[0],
          last_name: input[1],
          phone: phone
        }
        search params

        if browser.span(id: "spanNames1_0").exists?
          click_report
          get_data params
          ap "HAS DATA"
        else
          ap "NOT FOUND"
          csv_writer << [params[:first_name], params[:last_name], params[:phone], "NOT FOUND"]
        end

        time = Random.rand(15)
        ap time
        sleep(time)
      end
    rescue Exception => e
      ap e.backtrace
    end

    csv_writer.close
    close_browser
  end

  def login
    browser.goto "https://www.nexis.com/auth/signoff.do"
    browser.text_field(name: "webId").set "billytran"
    browser.text_field(name: "password").set "blackline182"
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
    browser.text_field(id: "MainContent_Phone").set params[:phone]
    
    browser.button(id: "MainContent_formSubmit_searchButton").click
    sleep 1

    redirect_url = browser.url
    if redirect_url.index("url=")
      browser.goto URI.unescape(redirect_url[redirect_url.index("url=")+4..-1])
    end
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

    email_section = browser.div(id: "SubjectSummary_EXPSEC_SubSum").text
    emails = email_section[email_section.index("E-Mail Sources")..-1].split("\n")[1..-1] if email_section.include? "E-Mail Sources"
    
    csv_writer << [params[:first_name], params[:last_name], params[:phone], emails.join(",")]
  end

  def remove_format_phone(phone)
    phone_tmp = phone.gsub(/[^0-9A-Za-z]/, '').downcase

    if phone_tmp.length >= 10
      phone_tmp = phone_tmp[0..9]
    end

    ActiveSupport::NumberHelper.number_to_phone(phone_tmp)
  end

  def close_browser
    # browser.goto "https://www.nexis.com/auth/signoff.do"
    browser.quit
  end
end
