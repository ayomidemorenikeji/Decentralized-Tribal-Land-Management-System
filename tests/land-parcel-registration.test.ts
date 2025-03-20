import { describe, it, expect, beforeEach } from "vitest"

// Mock the Clarity contract environment
const mockContract = {
  admin: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  nextParcelId: 1,
  landParcels: new Map(),
  
  // Mock functions
  registerParcel: function (north, east, south, west, landType) {
    const parcelId = this.nextParcelId
    
    if (this.txSender !== this.admin) {
      return { err: 403 }
    }
    
    this.landParcels.set(parcelId, {
      owner: this.txSender,
      northBoundary: north,
      eastBoundary: east,
      southBoundary: south,
      westBoundary: west,
      landType: landType,
      registrationDate: 123, // Mock block height
    })
    
    this.nextParcelId++
    return { ok: parcelId }
  },
  
  getParcel: function (parcelId) {
    return this.landParcels.get(parcelId) || null
  },
  
  updateParcel: function (parcelId, north, east, south, west, landType) {
    if (this.txSender !== this.admin) {
      return { err: 403 }
    }
    
    const parcel = this.landParcels.get(parcelId)
    if (!parcel) {
      return { err: 403 }
    }
    
    this.landParcels.set(parcelId, {
      ...parcel,
      northBoundary: north,
      eastBoundary: east,
      southBoundary: south,
      westBoundary: west,
      landType: landType,
    })
    
    return { ok: true }
  },
  
  transferParcel: function (parcelId, newOwner) {
    const parcel = this.landParcels.get(parcelId)
    if (!parcel || parcel.owner !== this.txSender) {
      return { err: 403 }
    }
    
    this.landParcels.set(parcelId, {
      ...parcel,
      owner: newOwner,
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

describe("Land Parcel Registration Contract", () => {
  beforeEach(() => {
    // Reset contract state before each test
    mockContract.nextParcelId = 1
    mockContract.landParcels = new Map()
    mockContract.admin = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    mockContract.txSender = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
  })
  
  it("should register a new parcel", () => {
    const result = mockContract.registerParcel(100, 200, 300, 400, "Forest")
    
    expect(result).toEqual({ ok: 1 })
    expect(mockContract.landParcels.size).toBe(1)
    
    const parcel = mockContract.getParcel(1)
    expect(parcel).toEqual({
      owner: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
      northBoundary: 100,
      eastBoundary: 200,
      southBoundary: 300,
      westBoundary: 400,
      landType: "Forest",
      registrationDate: 123,
    })
  })
  
  it("should not allow unauthorized users to register parcels", () => {
    mockContract.txSender = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    
    const result = mockContract.registerParcel(100, 200, 300, 400, "Forest")
    
    expect(result).toEqual({ err: 403 })
    expect(mockContract.landParcels.size).toBe(0)
  })
  
  it("should update a parcel", () => {
    // First register a parcel
    mockContract.registerParcel(100, 200, 300, 400, "Forest")
    
    // Then update it
    const result = mockContract.updateParcel(1, 150, 250, 350, 450, "Grassland")
    
    expect(result).toEqual({ ok: true })
    
    const parcel = mockContract.getParcel(1)
    expect(parcel.landType).toBe("Grassland")
    expect(parcel.northBoundary).toBe(150)
  })
  
  it("should transfer parcel ownership", () => {
    // First register a parcel
    mockContract.registerParcel(100, 200, 300, 400, "Forest")
    
    // Then transfer it
    const newOwner = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    const result = mockContract.transferParcel(1, newOwner)
    
    expect(result).toEqual({ ok: true })
    
    const parcel = mockContract.getParcel(1)
    expect(parcel.owner).toBe(newOwner)
  })
  
  it("should not allow unauthorized users to transfer parcels", () => {
    // First register a parcel
    mockContract.registerParcel(100, 200, 300, 400, "Forest")
    
    // Change the sender to someone else
    mockContract.txSender = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    
    // Try to transfer it
    const newOwner = "ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5YC7WF3G8"
    const result = mockContract.transferParcel(1, newOwner)
    
    expect(result).toEqual({ err: 403 })
    
    const parcel = mockContract.getParcel(1)
    expect(parcel.owner).toBe("ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM")
  })
  
  it("should change admin", () => {
    const newAdmin = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    const result = mockContract.setAdmin(newAdmin)
    
    expect(result).toEqual({ ok: true })
    expect(mockContract.admin).toBe(newAdmin)
  })
})

