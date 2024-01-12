qsort:
	rm -rf xsim.dir/ *.log *.pb *.jou *.wdb *.vcd
	xvlog -f ./include.rtl.list.xsim ./tb/qsort_tb.v
	xelab -top qsort_tb -snapshot qsort_tb_elab
	xsim qsort_tb_elab -R
