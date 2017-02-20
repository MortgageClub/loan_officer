require "watir"
require "csv"

class Crawler
  attr_accessor :browser, :csv, :zip, :page, :zips

  def initialize(zip = "", page = 1)
    @browser = Watir::Browser.new
    @zips = []
    @csv = CSV.open("public/output_loan_officer.csv", "ab")
    @zip = zip
    @page = page
  end

  def call
    go_to_homepage
    begin
      if zip.present?
        search
        get_loan_officer
      else
        @zips.each do |zip|
          @zip = zip
          search
          get_loan_officer
        end
      end
    rescue Exception => e
      ap e
    end

    close_browser
    csv.close
  end

  def go_to_homepage
    browser.goto "http://www.nmlsconsumeraccess.org/"
    browser.text_field(id: "searchText").set "95111"
    browser.button(id: "searchButton").click
    browser.checkbox(id: "ctl00_MainContent_cbxAgreeToTerms").click
    browser.image(id: "c_turingtestpage_ctl00_maincontent_captcha1_CaptchaImage").screenshot("public/captcha.png")

    client = TwoCaptcha.new("69b005359aaa1c0ca7c3bdf22d04de48")
    captcha = client.decode!(raw64: Base64.encode64(File.open('public/captcha.png', 'rb').read))
    browser.text_field(id: "ctl00_MainContent_txtTuringText").set captcha.text.upcase
    browser.button(id: "ctl00_MainContent_btnContinue").click
  end

  def search
    sleep 2
    browser.goto "http://www.nmlsconsumeraccess.org/Home.aspx/SubSearch?searchText=#{zip}&entityType=INDIVIDUAL&state=CA&Page=#{page}"
    sleep 2
    browser.refresh
    sleep 2
  end

  def get_loan_officer
    while true do
      size = browser.tds(class: "main").length

      0.upto(size - 1) do |index|
        sleep 2
        bypass_captcha
        ap browser.tds(class: "main").length
        td = browser.tds(class: "main")[index]

        td.a(class: "individual").click
        sleep 2
        bypass_captcha

        name = browser.p(class: "individual").text
        nmls = browser.table(class: "data").tds(class: "divider")[0].text
        phone = browser.table(class: "data").tds(class: "divider")[1].text

        companies = []

        office_locations_table = browser.divs(class: "grid_950").select {|grid| grid.text.include? "Office Locations"}.first
        locations = office_locations_table.table(class: "data").tbody.trs

        unless locations[1].text.include? "None"
          locations[1..-1].each do |location|
            companies << {
              name: location.tds[0].text,
              nmls_id: location.tds[1].text,
              address: location.tds[3].text,
              start_date: Date.strptime(location.tds[-2].text, "%m/%d/%Y"),
              zip: location.tds[-3].text
            }
          end

          company = companies.sort_by{|company| company[:start_date]}.last
          csv << [name, nmls, phone, company[:name], company[:nmls_id], company[:address], company[:zip]]
          ap [name, nmls, phone, company[:name], company[:nmls_id], company[:address], company[:zip]]
        else
          csv << [name, nmls, phone, "", "", "", zip]
        end

        browser.back
        sleep 2
      end

      bypass_captcha

      ap "Zip Code: #{zip}"
      if browser.li(class: "nextOn").exists?
        browser.li(class: "nextOn").click

        sleep 2
        bypass_captcha
      else
        break
      end
    end
  end

  def bypass_captcha
    if browser.image(id: "c_turingtestpage_ctl00_maincontent_captcha1_CaptchaImage").exists?
      browser.image(id: "c_turingtestpage_ctl00_maincontent_captcha1_CaptchaImage").screenshot("public/captcha.png")

      client = TwoCaptcha.new("69b005359aaa1c0ca7c3bdf22d04de48")
      captcha = client.decode!(raw64: Base64.encode64(File.open('public/captcha.png', 'rb').read))
      browser.text_field(id: "ctl00_MainContent_txtTuringText").set captcha.text.upcase
      browser.button(id: "ctl00_MainContent_btnContinue").click
      sleep 2
    end
  end

  def close_browser
    browser.quit
  end
end