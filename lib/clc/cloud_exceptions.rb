module Clc
  module CloudExceptions
    class Error < StandardError; end
    class BadRequest < Error; end
    class Unauthorized < Error; end
    class Forbidden < Error; end
    class NotFound < Error; end
    class InternalServerError < Error; end
    class UnknownError < Error
      def initialize
        super('Something went wrong')
      end
    end

    class Handler < Faraday::Response::Middleware
      def on_complete(response)
        case response[:status]
        when 400
          raise Clc::CloudExceptions::BadRequest, error_message_400(response)
        when 401
          raise Clc::CloudExceptions::Unauthorized, error_message_400(response)
        when 403
          raise Clc::CloudExceptions::Forbidden, error_message_400(response)
        when 404
          raise Clc::CloudExceptions::NotFound, error_message_400(response)
        when 500
          raise Clc::CloudExceptions::InternalServerError, error_message_500(response)
        when 400..600
          raise Clc::CloudExceptions::UnknownError
        end
      end

      private

      def error_message_400(response)
        "#{response[:method].to_s.upcase} #{response[:url]}: \
         #{response[:status]} #{response[:body]}"
      end

      def error_message_500(response, body = nil)
        "#{response[:method].to_s.upcase} #{response[:url]}: \
        #{[response[:status].to_s + ':', body].compact.join(' ')}"
      end
    end
  end
end
