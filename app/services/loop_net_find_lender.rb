require "watir"
require "csv"

class LoopNetFindLender
  attr_accessor :browser, :csv, :addresses, :header

  def initialize
    @browser = Watir::Browser.new
    @browser.window.maximize
    @header = [
      "Address", "Primary Property Type 1", "Property Sub-type 1", "LoopNet MPID 1",  "No. Units 1", "No. Stories 1", "Year Built 1", "Ground Floor 1", "Building Improvement Type 1", "Building Code 1",
      "APN/Parcel ID Property 1", "Census Tract 1", "Building Size 1",  "Lot Size 1", "Lot Number 1", "Zoning 1",
      "APN/Parcel ID Property 2", "Census Tract 2", "Building Size 2",  "Lot Size 2", "Lot Number 2", "Zoning 2",
      "APN/Parcel ID Property 3", "Census Tract 3", "Building Size 3",  "Lot Size 3", "Lot Number 3", "Zoning 3",
      "Date 1", "Event 1", "APN/Parcel ID Owner 1", "Owner 1", "Address 1", "Rights 1", "Sale Price 1", "Mortgage Date 1", "Mortgage Details (at time of loan) 1", "Mortgage Deed Type 1", "Lender Name 1", "Lender Address 1",
      "Date 2", "Event 2", "APN/Parcel ID Owner 2", "Owner 2", "Address 2", "Rights 2", "Sale Price 2", "Mortgage Date 2", "Mortgage Details (at time of loan) 2", "Mortgage Deed Type 2", "Lender Name 2", "Lender Address 2",
      "Date 3", "Event 3", "APN/Parcel ID Owner 3", "Owner 3", "Address 3", "Rights 3", "Sale Price 3", "Mortgage Date 3", "Mortgage Details (at time of loan) 3", "Mortgage Deed Type 3", "Lender Name 3", "Lender Address 3"
    ]

    @csv = CSV.open("public/output_loop_find_lender.csv", "ab")
    @csv << header
    @addresses = CSV.read("public/CVS locations.csv")
  end

  def call
    login

    @addresses.each do |address|
      ap "-----------------------------------start-----------------------------------"
      begin
        search(address)
        get_properties
      rescue Exception => e
        ap e
      end
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

  def search(address)
    ap address

    browser.goto "http://www.loopnet.com/propertyrecords/"

    browser.text_field(id: "Location").set address
    browser.link(id: "location_search_btn").click
  end

  def get_properties
    sleep(4)
    if browser.link(class: "searchResultPhoto").exists?
      links = []

      while true do
        links += browser.links(class: "searchResultPhoto").map { |link| link.attribute_value("href") }

        next_link = browser.div(id: "pagingbottom").span(class: "caret-right")
        break unless next_link.exists?

        next_link.click
        sleep(3)
      end

      links.each do |link|
        browser.goto link
        sleep(2)
        row = CSV::Row.new(header,[])

        row["Address"] = browser.div(class: "listingProfileDetail").h1.text

        if browser.link(id: "lnkMenuPropertyDetails").exists?
          browser.link(id: "lnkMenuPropertyDetails").click

          browser.tables(class: "keyValue").each_with_index do |table, index|
            next if index > 2

            table.tbody.trs.each do |tr|
              if tr.th.text == "APN/Parcel ID"
                row["#{tr.th.text} Property #{index + 1}"] = tr.td.text
              else
                row["#{tr.th.text} #{index + 1}"] = tr.td.text
              end
            end
          end
        end

        if browser.link(id: "lnkMenuOwnerMortgage").exists?
          browser.link(id: "lnkMenuOwnerMortgage").click

          browser.tables(class: "keyValue").each_with_index do |table, index|
            next if index > 2

            row["Date #{index + 1}"] = table.thead.text
            table.tbody.trs.each do |tr|
              if tr.th.text == "APN/Parcel ID"
                row["#{tr.th.text} Owner #{index + 1}"] = tr.td.text
              else
                row["#{tr.th.text} #{index + 1}"] = tr.td.text
              end
            end
          end
        end

        csv << row
      end
    else
      ap "No Data Available"
    end
  end

  def close_browser
    browser.goto "http://www.loopnet.com/xNet/MainSite/User/logoff.aspx?LinkCode=850"
    browser.quit
  end
end
