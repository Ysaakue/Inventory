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
      row << cp.product.value #VLR UNIT
      row << cp.product.value * cp.product.current_stock #VLRT TOTAL
      row << cp.product.current_stock #SALDO INICIAL
      row << (cp.results[0].blank?? '-' : cp.results[0].quantity_found) #CONT 1
      row << (cp.results[1].blank?? '-' : cp.results[1].quantity_found) #CONT 2
      row << (cp.results[2].blank?? '-' : cp.results[2].quantity_found) #CONT 3
      row << (cp.results[3].blank?? '-' : cp.results[3].quantity_found) #CONT 4
      row << cp.results.last.quantity_found #SALDO FINAL
      row << (cp.results.last.quantity_found*100)/cp.product.current_stock #RESULTADO %
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
      row << cp.results.last.quantity_found * cp.product.value #VLR TOTAL FINAL
      row << ((cp.results.last.quantity_found * cp.product.value)*100)/(cp.product.current_stock * cp.product.value) #RESULTADO VLR %
      output << CSV.generate_line(row)
    end
    output
  end
end
