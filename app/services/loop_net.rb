require "watir"
require "csv"

class LoopNet
  attr_accessor :browser, :csv, :state

  def initialize(state)
    @browser = Watir::Browser.new
    @browser.window.maximize
    @state = state
    @csv = CSV.open("public/output_loop_net_#{state}.csv", "ab")
  end

  def call
    login
    begin
      search(state)
      get_properties
    rescue Exception => e
      ap e
    end

    close_browser
    csv.close
  end

  def login
    browser.goto "http://www.loopnet.com/xNet/MainSite/User/customlogin.aspx?LinkCode=31824"
    browser.text_field(id: "ctlLogin_LogonEmail").set "dane.chodos@blacklinelending.com"
    browser.text_field(id: "ctlLogin_LogonPassword").set "Pickman45"
    browser.link(id: "ctlLogin_btnLogon").click
  end

  def search(state)
    browser.goto "http://www.loopnet.com/for-sale/ca/retail/"
    browser.section(class: "onboarding-modal").click
    browser.button(value: "Filters").click

    browser.checkbox(id: "businessesForSale").set false
    browser.checkbox(id: "vacantProperties").set false

    browser.checkbox(id: "netLeasedProperties").set true
    browser.checkbox(id: "tenancySingle").set true

    browser.text_field(id: "capRateRange").set "4"
    browser.text_field(name: "CapRateRangeMax").set "8.5"
    
    browser.div(class: "price-range-group").div(class: "range-container").text_field(placeholder: "Min $").set("750000")
    
    browser.span(class: "ui-select-match-close").click if browser.span(class: "ui-select-match-close").exists?
    browser.text_field(class: "ui-select-search").set state
    browser.link(class: "ui-select-choices-row-inner").click

    browser.button(value: "Search", class: "button primary").click
  end

  def get_properties
    sleep(5)
    id = browser.article(class: "placard").attribute_value("data-id")
    browser.goto "http://www.loopnet.com/Listing/#{id}"
    # browser.goto "http://www.loopnet.com/Listing/20126552/3388-Fowler-St-Fort-Myers-FL/"

    while true do
      address = browser.div(class: "property-info").div(class: "column-09").h1.text.split("\n")[0]
      price = browser.div(class: "property-price-wrap").text
      city_state_zip = browser.div(class: "property-info").span(class: "city-state").text

      lease_left = ""
      browser.table(class: "property-data").trs.each do |tr|
        next unless tr.text.index "Property Use Type"
        lease_left = tr.tds[0].text.index("Property Use Type") ? tr.tds[1].text : tr.tds[3].text
      end

      full_name = browser.div(class: "broker-basic-info").text.split("\n")[0]
      phone_number = browser.div(class: "broker-basic-info").text.split("\n")[1]
      company_name = browser.p(class: "company-name").exist? ? browser.p(class: "company-name").text : (browser.section(class: "company-logo").img.exist? ? browser.section(class: "company-logo").img.attribute_value("alt") : "Company Not Provided")

      csv << [browser.url, address, city_state_zip, price, lease_left, full_name, phone_number, company_name]
      
      next_link = browser.link(class: "caret-right-large")
      
      break unless next_link.exists?
      next_link.click
    end
  end

  def close_browser
    browser.goto "http://www.loopnet.com/xNet/MainSite/User/logoff.aspx?LinkCode=850"
    browser.quit
  end
end