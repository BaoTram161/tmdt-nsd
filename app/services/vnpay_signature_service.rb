require "openssl"
require "uri"

class VnpaySignatureService
  SIGNATURE_KEYS = %w[
    vnp_SecureHash
    vnp_SecureHashType
  ].freeze

  def self.generate(params, secret:)
    query = canonical_query(params)
    OpenSSL::HMAC.hexdigest("SHA512", secret, query)
  end

  def self.valid?(params, secret:)
    supplied_signature = params["vnp_SecureHash"].to_s
    return false if supplied_signature.blank? || secret.blank?

    expected_signature = generate(params, secret: secret)

    ActiveSupport::SecurityUtils.secure_compare(
      expected_signature.downcase,
      supplied_signature.downcase
    )
  end

  def self.canonical_query(params)
    parameters = params.to_h.stringify_keys.except(*SIGNATURE_KEYS)

    URI.encode_www_form(
      parameters.sort_by { |key, _value| key }
    )
  end

  private_class_method :canonical_query
end
