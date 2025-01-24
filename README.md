# ProductTracker Smart Contract

## Overview

The **ProductTracker Smart Contract** is a robust and efficient blockchain-based solution designed for transparent tracking of product lifecycles and certifications. Built with Clarity on the Stacks blockchain, this smart contract enables a transparent, tamper-proof, and scalable supply chain management system. It ensures every product's status, ownership, and certification is immutable and accessible to all authorized stakeholders.

---

## Key Features

### 1. **Product Lifecycle Management**
- Track the status of a product through its lifecycle stages:
  - Produced
  - In Transit
  - Delivered
  - Quality Checked
- Maintain an immutable history of all status changes for each product.

### 2. **Certification Management**
- Add certifications to products such as:
  - Organic
  - Fair Trade
  - Sustainable
  - Quality Assured
- Validate the authenticity of certifications through approved authorities.
- Revoke certifications if they become invalid or compromised.

### 3. **Access Control**
- Only authorized participants can perform specific actions:
  - Contract owner assigns certification authorities.
  - Certification authorities add or revoke certifications.
  - Product owners update product statuses.

### 4. **Transparency and Trust**
- Immutable product history and certification records ensure data integrity.
- Publicly accessible functions provide real-time verification of product status and certifications.

---

## Smart Contract Components

### **Data Structures**

#### 1. Product Details
A `product-details` map stores information about each product:
- `owner`: Principal address of the product owner.
- `current-status`: Current status of the product.
- `history`: List of past status changes with timestamps.

#### 2. Product Certifications
A `product-certifications` map tracks certifications for each product:
- `issuer`: Address of the certification authority.
- `timestamp`: Block height when the certification was issued.
- `valid`: Boolean indicating if the certification is active.

#### 3. Certification Authorities
A `certification-authorities` map identifies approved authorities for specific certification types:
- `authority`: Principal address of the authority.
- `cert-type`: Certification type (e.g., Organic, Fair Trade).
- `approved`: Boolean indicating approval status.

---

### **Public Functions**

#### 1. **register-product**
Registers a new product with an initial status.
```clarity
(register-product (product-id uint) (initial-status uint)) -> (response bool uint)
```
- Validates the product ID and initial status.
- Stores product details in the `product-details` map.

#### 2. **update-product-status**
Updates the status of an existing product.
```clarity
(update-product-status (product-id uint) (new-status uint)) -> (response bool uint)
```
- Verifies product ownership or contract ownership.
- Appends the new status to the product's history.

#### 3. **add-certification-authority**
Grants authority to issue specific certifications.
```clarity
(add-certification-authority (authority principal) (cert-type uint)) -> (response bool uint)
```
- Restricted to the contract owner.

#### 4. **add-certification**
Adds a certification to a product.
```clarity
(add-certification (product-id uint) (cert-type uint)) -> (response bool uint)
```
- Validates the certification authority and prevents duplicate certifications.

#### 5. **revoke-certification**
Revokes an existing certification for a product.
```clarity
(revoke-certification (product-id uint) (cert-type uint)) -> (response bool uint)
```
- Restricted to the certification authority or contract owner.

#### 6. **verify-certification**
Checks the validity of a product's certification.
```clarity
(verify-certification (product-id uint) (cert-type uint)) -> (response bool uint)
```
- Returns whether the certification is active.

#### 7. **get-product-history**
Retrieves the lifecycle history of a product.
```clarity
(get-product-history (product-id uint)) -> (response (list 10 {status: uint, timestamp: uint}) uint)
```
- Provides a detailed timeline of status changes.

#### 8. **get-product-status**
Gets the current status of a product.
```clarity
(get-product-status (product-id uint)) -> (response uint uint)
```
- Returns the current lifecycle status.

#### 9. **get-certification-details**
Fetches detailed information about a product's certification.
```clarity
(get-certification-details (product-id uint) (cert-type uint)) -> (response {issuer: principal, timestamp: uint, valid: bool} uint)
```
- Provides issuer details, timestamp, and validity status.

---

## Constants

### **Product Statuses**
- `PRODUCT_STATUS_PRODUCED`: u1
- `PRODUCT_STATUS_IN_TRANSIT`: u2
- `PRODUCT_STATUS_DELIVERED`: u3
- `PRODUCT_STATUS_QUALITY_CHECKED`: u4

### **Certification Types**
- `CERT_TYPE_ORGANIC`: u1
- `CERT_TYPE_FAIR_TRADE`: u2
- `CERT_TYPE_SUSTAINABLE`: u3
- `CERT_TYPE_QUALITY_ASSURED`: u4

### **Error Codes**
- `ERR_UNAUTHORIZED`: err u1
- `ERR_INVALID_PRODUCT`: err u2
- `ERR_STATUS_UPDATE_FAILED`: err u3
- `ERR_INVALID_STATUS`: err u4
- `ERR_INVALID_CERTIFICATION`: err u5
- `ERR_CERTIFICATION_EXISTS`: err u6

---

## Use Cases

1. **Food Supply Chain**:
   - Track the journey of perishable goods to ensure freshness.
   - Validate organic or fair-trade certifications.

2. **Pharmaceutical Industry**:
   - Monitor drug production and transportation to ensure safety and compliance.
   - Certify drugs with quality-assurance seals.

3. **Luxury Goods**:
   - Authenticate high-value items like jewelry or designer products.
   - Prevent counterfeiting with immutable certification records.

4. **Environmental Initiatives**:
   - Certify sustainably sourced products.
   - Track carbon-neutral supply chains.

---


Transform supply chain management with the transparency and immutability of blockchain using the ProductTracker Smart Contract. Let's build trust and efficiency together!

