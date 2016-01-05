module Clc
  module CloudExceptions
    class Error < StandardError; end
    class BadRequest < Error; end
    class Unauthorized < Error; end
    class Forbidden < Error; end
    class NotFound < Error; end
    class InternalServerError < Error; end
    class UnknownError < Error; end
    class MethodNotAllowed < Error; end

    class Handler < Faraday::Response::Middleware
      def on_complete(response)
        case response[:status]
        when 400
          raise Clc::CloudExceptions::BadRequest, error_message(response)
        when 401
          raise Clc::CloudExceptions::Unauthorized, error_message(response)
        when 403
          raise Clc::CloudExceptions::Forbidden, error_message(response)
        when 404
          raise Clc::CloudExceptions::NotFound, error_message(response)
        when 405
          raise Clc::CloudExceptions::MethodNotAllowed, error_message(response)
        when 500
          raise Clc::CloudExceptions::InternalServerError, error_message(response)
        when 400..600
          raise Clc::CloudExceptions::UnknownError, error_message(response)
        end
      end

      private

      def error_message(response)
        "#{response[:status]} #{response[:url]} #{response[:body]}"
      end
    end
  end
end
