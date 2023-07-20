module shareable_coupon::coupon {
  use sui::coin;
  use sui::object::{Self, UID};
  use sui::sui::SUI;
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use std::string::{Self, String};
  use std::vector::{Self};

  /// Sending to wrong recipient.
  const EWrongRecipient: u64 = 0;

  /// Percentage discount out of range.
  const EOutOfRangeDiscount: u64 = 1;

  /// Discount coupon NFT.
  struct Coupon has key, store {
    id: UID,
    name: String,
    image: String,
    is_shared: bool,
    // percentage discount [1-100]
    discount: u8,
    // expiration timestamp (UNIX time) - app specific
    expiration: u64,
    owner: address,
    issuer: address,
  }

  struct CouponGroup has key {
    id: UID,
    // coupon issuer
    issuer: address,
    coupons: vector<Coupon>,
  }

  /// Simple issuer getter.
  // public fun issuer(coupon: &DiscountCoupon): address {
  //   coupon.issuer
  // }
  public entry fun mint_coupon_group(ctx: &mut TxContext) {
    let coupon_group = CouponGroup {
      id: object::new(ctx),
      issuer: tx_context::sender(ctx),
      coupons: vector::empty(),
    };
    transfer::transfer(coupon_group, tx_context::sender(ctx));
  }

  public entry fun mint_coupon(
    group: &mut CouponGroup,
    name: String,
    image: String,
    discount: u8,
    expiration: u64,
    recipient: address,
    ctx: &mut TxContext,
  ) {
    assert!(discount > 0 && discount <= 100, EOutOfRangeDiscount);
    let coupon = Coupon {
      id: object::new(ctx),
      name,
      image,
      is_shared: false,
      discount,
      expiration,
      owner: recipient,
      issuer: group.issuer,
    };
    vector::push_back(&mut group.coupons, coupon);
    transfer::transfer(coupon, recipient);
  }

  // /// Mint then transfer a new `DiscountCoupon` NFT, and top up recipient with some SUI.
  // public entry fun mint_and_topup(
  //   coin: coin::Coin<SUI>,
  //   discount: u8,
  //   expiration: u64,
  //   recipient: address,
  //   ctx: &mut TxContext,
  // ) {
  //   assert!(discount > 0 && discount <= 100, EOutOfRangeDiscount);
  //   let coupon = DiscountCoupon {
  //     id: object::new(ctx),
  //     issuer: tx_context::sender(ctx),
  //     discount,
  //     expiration,
  //   };
  //   transfer::transfer(coupon, recipient);
  //   transfer::public_transfer(coin, recipient);
  // }

  // /// Burn DiscountCoupon.
  // public entry fun burn(nft: DiscountCoupon) {
  //   let DiscountCoupon { id, issuer: _, discount: _, expiration: _ } = nft;
  //   object::delete(id);
  // }

  public entry fun transfer(coupon: Coupon, recipient: address) {
    assert!(&coupon.owner == &recipient, EWrongRecipient);
    coupon.is_shared = false;
    transfer::transfer(coupon, recipient);
  }
}