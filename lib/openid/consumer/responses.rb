module OpenID
  class Consumer
    # Code returned when either the of the
    # OpenID::OpenIDConsumer.begin_auth or OpenID::OpenIDConsumer.complete_auth
    # methods return successfully.
    SUCCESS = :success

    # Code OpenID::OpenIDConsumer.complete_auth
    # returns when the value it received indicated an invalid login.
    FAILURE = :failure

    # Code returned by OpenIDConsumer.complete_auth when the user
    # cancels the operation from the server.
    CANCEL = :cancel

    # Code returned by OpenID::OpenIDConsumer.complete_auth when the
    # OpenIDConsumer instance is in immediate mode and ther server sends back a
    # URL for the user to login with.
    SETUP_NEEDED = :setup_needed


    module Response
      attr_reader :endpoint, :identity_url

      def status
        self.class::STATUS
      end

      def endpoint=(endpoint)
        @endpoint = endpoint
        if endpoint.nil?
          @identity_url = nil
        else
          @identity_url = endpoint.claimed_id
        end
      end
    end

    # A successful acknowledgement from the OpenID server that the
    # supplied URL is, indeed controlled by the requesting agent.
    class SuccessResponse
      include Response

      STATUS = SUCCESS

      attr_reader :message, :signed_fields

      def initialize(endpoint, message, signed_fields)
        # Don't use :endpoint=, because endpoint should never be nil
        # for a successfull transaction.
        @endpoint = endpoint
        @identity_url = endpoint.claimed_id
        @message = message
        @signed_fields = signed_fields
      end

      # Was this authentication response an OpenID 1 authentication
      # response?
      def is_openid1
        @message.is_openid1
      end

      # Return whether a particular key is signed, regardless of its
      # namespace alias
      def signed?(ns_uri, ns_key)
        @signed_fields.member?(@message.get_key(ns_uri, ns_key))
      end

      # Return the specified signed field if available, otherwise
      # return default
      def get_signed(ns_uri, ns_key, default=nil)
        if singed?(ns_uri, ns_key)
          return @message.get_arg(ns_uri, ns_key, default)
        else
          return default
        end
      end

      # Get signed arguments from the response message.  Return a dict
      # of all arguments in the specified namespace.  If any of the
      # arguments are not signed, return nil.
      def get_signed_ns(ns_uri)
        msg_args = @message.get_args(ns_uri)
        msg_args.each do |key|
          if !signed?(ns_uri, key)
            return nil
          end
        end
        return msg_args
      end

      # Return response arguments in the specified namespace.
      # If require_signed is true and the arguments are not signed,
      # return nil.
      def extension_response(namespace_uri, require_signed)
        if require_signed
          get_signed_ns(namespace_uri)
        else
          @message.get_args(namespace_uri)
        end
      end

      def ==(other)
        if !other.instance_of?(self.class)
          return false
        end

        [
         'endpoint',
         'identity_url',
         'message',
         'signed_fields',
        ].each do |var_name|
          var_name = '@' + var_name
          if instance_var_get(var_name) != other.instance_var_get(var_name)
            return false
          end
        end
      end
    end

    class FailureResponse
      include Response
      STATUS = FAILURE

      attr_reader :message, :contact, :reference
      def initialize(endpoint, message, contact=nil, reference=nil)
        self.endpoint=(endpoint)
        @message = message
        @contact = contact
        @reference = reference
      end
    end

    class CancelResponse
      include Response
      STATUS = CANCEL
      def initialize(endpoint)
        self.endpoint=(endpoint)
      end
    end

    class SetupNeededResponse
      include Response
      STATUS = SETUP_NEEDED
      def initialize(endpoint, setup_url)
        self.endpoint=(endpoint)
        @setup_url = setup_url
      end
    end
  end
end