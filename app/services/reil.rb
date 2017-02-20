require "watir"
require "csv"

class Reil
  attr_accessor :browser, :properties, :page, :csv, :from, :to, :current_url

  def initialize(page = 1, from = 0, to = -1)
    @browser = Watir::Browser.new
    @page = page
    @csv = CSV.open("public/output_properties.csv", "ab")
    @from = from
    @to = to
  end

  def call
    begin
      login
      30.upto(50).each do |index|
        @properties = []
        @page = index
        browser.goto current_url
        get_data
        get_more_info
      end
    rescue Exception => e
      ap e
    end

    close_browser
    csv.close
  end

  def login
    browser.goto "http://reil.com/Account/Login.aspx?ReturnUrl=%2f"
    browser.button(id: "MainContent_UCLogin_ibtnSignIn").click
    browser.text_field(id: "j_username").set "35003058"
    browser.execute_script("$('#password').val('mortgage180')")
    browser.execute_script("$('#j_password').val('mortgage180')")
    browser.button(id: "loginbtn").click

    browser.text_field(id: "MainContent_txtAgentName").set "Trung Lam"
    browser.button(id: "MainContent_butAssist").click
    browser.goto "http://search.mlslistings.com/Matrix/Search/Residential"
    browser.a(id: "ctl01_m_ucSpeedBar_m_ucrs_m_lbOpenDropDown").click
    sleep 2
    browser.td(id: "sh$29174019").click
    @current_url = browser.url
  end

  def get_data
    if page > 1
      browser.execute_script("__doPostBack('m_DisplayCore','Redisplay|,#{(page-1)*100}')")
      sleep(2)
    end

    browser.div(id: "m_pnlDisplay").tbody.trs[from..to].each do |tr|
      tds = tr.tds
      ap tr.text
      properties << {
        address: tds[2].text,
        dom: tds[3].text,
        postal_code: tds[4].text,
        zip_code: tds[5].text,
        agent_remarks: tds[6].text,
        selling_agent_full_name: tds[7].text,
        selling_agent_license_id: tds[8].text,
        selling_agent_email: tr.tds[9].text,
        buyer_financing: tr.tds[10].text,
        list_agent_full_name: tr.tds[11].text,
        list_agent_license_id: tr.tds[13].text,
        owner_name: tr.tds[12].text,
        list_agent_email: tr.tds[14].text,
        sale_price: tr.tds[15].text,
        close_date: tr.tds[16].text,
        info_url: tr.tds[17].a.attribute_value("href"),
        property_owner_name: nil,
        property_owner_name_2: nil,
        current_loan_date: nil,
        current_loan_amount: nil,
        current_loan_lender: nil,
        original_loan_date: nil,
        original_loan_amount: nil,
        original_loan_lender: nil,
      }
    end
  end

  def get_more_info
    ap "Current page: #{page}"

    properties.each_with_index do |property, index|
      browser.goto property[:info_url]

      sales_history = browser.divs(class: "section").select{|section| section.text.include? "Sales History"}.last
      mortgage_history = browser.divs(class: "section").select{|section| section.text.include? "Mortgage History"}.last
      ap "Current index: #{index}"

      if sales_history && sales_history.exists?
        col_owner_name = sales_history.table(class: "multiColumnTable").trs.select{|tr| tr.text.include? "Owner Name:"}.first
        col_owner_name_2 = sales_history.table(class: "multiColumnTable").trs.select{|tr| tr.text.include? "Owner Name 2:"}.first

        if col_owner_name && col_owner_name.exists?
          property[:property_owner_name] = col_owner_name.tds[0].text.include?("Owner Name") ? col_owner_name.tds[1].text : col_owner_name.tds[3].text
        end

        if col_owner_name_2 && col_owner_name_2.exists?
          property[:property_owner_name_2] = col_owner_name_2.tds[0].text.include?("Owner Name 2") ? col_owner_name_2.tds[1].text : col_owner_name_2.tds[3].text
        end
      end

      if mortgage_history && mortgage_history.exists?
        table = mortgage_history.table(class: "dataGridTable")

        if table && table.exists?
          property[:current_loan_date] = table.trs[0].tds[1].text
          property[:current_loan_amount] = table.trs[1].tds[1].text
          property[:current_loan_lender] = table.trs[2].tds[1].text

          if table.trs[0].tds[2] && table.trs[0].tds[2].exists?
            property[:original_loan_date] = table.trs[0].tds[2].text
            property[:original_loan_amount] = table.trs[1].tds[2].text
            property[:original_loan_lender] = table.trs[2].tds[2].text
          end
        end
      end

      csv << property.to_a.map{|key, value| value}
    end
  end

  def close_browser
    browser.quit
  end

  # def has_original_loan?(property)
  #   return false if property[:original_loan_date].nil? || property[:recording_date].nil?

  #   original_loan_date = Date.strptime(property[:original_loan_date], "%m/%d/%Y")
  #   recording_date = Date.strptime(property[:recording_date], "%m/%d/%Y")

  #   (original_loan_date - recording_date).to_i.abs < 3
  # end
end
