import { describe, it, expect, beforeEach } from "vitest"

// Mock the Clarity contract environment
const mockContract = {
  admin: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  nextAllocationId: 1,
  benefitAllocations: new Map(),
  
  // Mock functions
  registerAllocation: function (parcelId, revenueAmount) {
    const allocationId = this.nextAllocationId
    
    if (this.txSender !== this.admin) {
      return { err: 403 }
    }
    
    const educationAmount = Math.floor((revenueAmount * 20) / 100)
    const healthcareAmount = Math.floor((revenueAmount * 20) / 100)
    const infrastructureAmount = Math.floor((revenueAmount * 20) / 100)
    const culturalAmount = Math.floor((revenueAmount * 20) / 100)
    const generalAmount = Math.floor((revenueAmount * 20) / 100)
    
    this.benefitAllocations.set(allocationId, {
      parcelId: parcelId,
      revenueAmount: revenueAmount,
      educationFund: educationAmount,
      healthcareFund: healthcareAmount,
      infrastructureFund: infrastructureAmount,
      culturalPreservationFund: culturalAmount,
      generalFund: generalAmount,
      allocationDate: 123, // Mock block height
    })
    
    this.nextAllocationId++
    return { ok: allocationId }
  },
  
  getAllocation: function (allocationId) {
    return this.benefitAllocations.get(allocationId) || null
  },
  
  updateAllocationPercentages: function (
      allocationId,
      educationPercent,
      healthcarePercent,
      infrastructurePercent,
      culturalPercent,
      generalPercent,
  ) {
    if (this.txSender !== this.admin) {
      return { err: 403 }
    }
    
    const allocation = this.benefitAllocations.get(allocationId)
    if (!allocation) {
      return { err: 403 }
    }
    
    // Check that percentages add up to 100
    if (educationPercent + healthcarePercent + infrastructurePercent + culturalPercent + generalPercent !== 100) {
      return { err: 403 }
    }
    
    const revenue = allocation.revenueAmount
    
    this.benefitAllocations.set(allocationId, {
      ...allocation,
      educationFund: Math.floor((revenue * educationPercent) / 100),
      healthcareFund: Math.floor((revenue * healthcarePercent) / 100),
      infrastructureFund: Math.floor((revenue * infrastructurePercent) / 100),
      culturalPreservationFund: Math.floor((revenue * culturalPercent) / 100),
      generalFund: Math.floor((revenue * generalPercent) / 100),
    })
    
    return { ok: true }
  },
  
  setAdmin: function (newAdmin) {
    if (this.txSender !== this.admin) {
      return { err: 403 }
    }
    
    this.admin = newAdmin
    return { ok: true }
  },
  
  // Mock transaction sender
  txSender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
}

describe("Community Benefit Contract", () => {
  beforeEach(() => {
    // Reset contract state before each test
    mockContract.nextAllocationId = 1
    mockContract.benefitAllocations = new Map()
    mockContract.admin = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    mockContract.txSender = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
  })
  
  it("should register a new benefit allocation", () => {
    const result = mockContract.registerAllocation(1, 1000)
    
    expect(result).toEqual({ ok: 1 })
    expect(mockContract.benefitAllocations.size).toBe(1)
    
    const allocation = mockContract.getAllocation(1)
    expect(allocation).toEqual({
      parcelId: 1,
      revenueAmount: 1000,
      educationFund: 200,
      healthcareFund: 200,
      infrastructureFund: 200,
      culturalPreservationFund: 200,
      generalFund: 200,
      allocationDate: 123,
    })
  })
  
  it("should update allocation percentages", () => {
    // First register an allocation
    mockContract.registerAllocation(1, 1000)
    
    // Then update its percentages
    const result = mockContract.updateAllocationPercentages(1, 30, 30, 20, 10, 10)
    
    expect(result).toEqual({ ok: true })
    
    const allocation = mockContract.getAllocation(1)
    expect(allocation.educationFund).toBe(300)
    expect(allocation.healthcareFund).toBe(300)
    expect(allocation.infrastructureFund).toBe(200)
    expect(allocation.culturalPreservationFund).toBe(100)
    expect(allocation.generalFund).toBe(100)
  })
  
  it("should not allow percentages that do not add up to 100", () => {
    // First register an allocation
    mockContract.registerAllocation(1, 1000)
    
    // Then try to update with invalid percentages
    const result = mockContract.updateAllocationPercentages(1, 30, 30, 20, 10, 5) // Only adds up to 95
    
    expect(result).toEqual({ err: 403 })
    
    // Allocation should remain unchanged
    const allocation = mockContract.getAllocation(1)
    expect(allocation.educationFund).toBe(200)
  })
})

