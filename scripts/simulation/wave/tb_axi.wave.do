set TOP tb_ma_data_path/master[1]
source ../test/axi.wave.do

set TOP tb_ma_data_path/master[0]
source ../test/axi.wave.do

set TOP tb_ma_data_path/slave[0]
source ../test/axi.wave.do