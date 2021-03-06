require 'active_support/concern'
require 'active_support/lazy_load_hooks'

module CryptKeeper
  module LogSubscriber
    module PostgresPgp
      FILTER = /(\(*)(?<operation>pgp_sym_encrypt|pgp_sym_decrypt|pgp_pub_encrypt|pgp_pub_decrypt|pgp_key_id)(\(+.*\)+)/im

      # Public: Prevents sensitive data from being logged
      #
      # event - An ActiveSupport::Notifications::Event
      #
      # Returns a boolean.
      def sql(event)
        payload = crypt_keeper_payload_parse(event.payload[:sql])
        event.payload[:sql] = crypt_keeper_filter_postgres_log(payload)
        super(event)
      end

      private

      # Private: Parses the payload to UTF.
      #
      # payload - the payload string
      #
      # Returns a string.
      def crypt_keeper_payload_parse(payload)
        payload.encode('UTF-8', 'binary',
          invalid: :replace, undef: :replace, replace: '')
      end

      # Private: Filters the payload.
      #
      # payload - the payload string
      #
      # Returns a string.
      def crypt_keeper_filter_postgres_log(payload)
        payload.gsub(FILTER) do |_|
          "#{$~[:operation]}([FILTERED])"
        end
      end
    end
  end
end

ActiveSupport.on_load :crypt_keeper_postgres_pgp_log do
  ActiveRecord::LogSubscriber.prepend CryptKeeper::LogSubscriber::PostgresPgp
end
