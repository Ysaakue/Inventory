class CsvBuilder
  attr_accessor :output, :header, :count

  def initialize(header, count, output = "")
    @output = output
    @header = header
    @count = count
  end

  def build
    output << CSV.generate_line(header)
    count.counts_products.lazy.each do |cp|
      row = []
      row << cp.product.code #COD
      row << cp.product.description #MATERIAL
      row << cp.product.unit_measurement #UND
      row << (('%.2f' % cp.product.value).gsub! '.',',') #VLR UNIT
      row << (('%.2f' % cp.total_value).gsub! '.',',') #VLRT TOTAL
      row << cp.product.current_stock #SALDO INICIAL
      row << (cp.results.order(:order)[0].blank?? '-' : cp.results.order(:order)[0].quantity_found) #CONT 1
      row << (cp.results.order(:order)[1].blank?? '-' : cp.results.order(:order)[1].quantity_found) #CONT 2
      row << (cp.results.order(:order)[2].blank?? '-' : cp.results.order(:order)[2].quantity_found) #CONT 3
      row << (cp.results.order(:order)[3].blank?? '-' : cp.results.order(:order)[3].quantity_found) #CONT 4
      row << cp.results.order(:order).last.quantity_found #SALDO FINAL
      row << cp.percentage_result #RESULTADO %
      streets = []
      stands  = []
      shelfs  = []
      if !cp.product.location.blank? && !cp.product.location["locations"].blank?
        cp.product.location["locations"].each do |location|
          streets << location["street"]
          stands  << location["stand"]
          shelfs  << location["shelf"]
        end
      end
      row << streets.join(',') #RUA
      row << stands.join(',') #ESTANTE
      row << shelfs.join(',') #PRATELEIRA
      row << (('%.2f' % cp.final_total_value).gsub! '.',',') #VLR TOTAL FINAL
      row << cp.percentage_result_value #RESULTADO VLR %
      output << CSV.generate_line(row)
    end
    output
  end
end
