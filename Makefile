.PHONY: preflight sim validate harden clean
RUN_TAG ?= kianv_ihp
CONFIG := librelane/config.yaml

preflight:
	bash scripts/preflight.sh

sim: preflight

validate:
	librelane --pdk ihp-sg13g2 --flow Chip $(CONFIG) --run-tag $(RUN_TAG)_validate --to Yosys.Synthesis

harden:
	librelane --pdk ihp-sg13g2 --flow Chip $(CONFIG) --run-tag $(RUN_TAG)

clean:
	rm -f sim/*.vvp sim/*.vcd

