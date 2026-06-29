import cocotb
from cocotb.clock import Clock

from cocotb.triggers import RisingEdge

@cocotb.test()
async def test_counter(dut):
    # Start Clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # Assert reset signal
    dut.rst.value = 1
    await RisingEdge(dut.clk)  # hold reset for one cycle

    # Check reset 
    assert dut.count.value == 0, f"Expected 0, got {dut.count.value}"

    # clear reset
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    # Increment counter by 10 
    for i in range(10):
        await RisingEdge(dut.clk)

    # Check counter value
    assert dut.count.value == 10, f"Expected 10, got {dut.count.value}"
    