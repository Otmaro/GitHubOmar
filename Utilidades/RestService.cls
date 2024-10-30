public with sharing class RestService {

    static final String URI = Setting__mdt.getInstance('RestURI')?.Value__c;
    static final String CODE = Setting__mdt.getInstance('RestCode')?.Value__c;

    public class RestServiceException extends Exception {
    }

    public static HttpResponse callout(String urlEndPoint, String json, String method, Integer timeout, Map<String, String> headers) {
        HttpResponse response;
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(( String.isNotBlank(urlEndPoint) ? urlEndPoint : getGeneralEndpoint()));
            request.setMethod(method);
            if (headers != null && headers.size() > 0) {
                for (String header : headers.keySet()) {
                    request.setHeader(header, headers.get(header));
                    System.debug('-WS-HEADER ' + header + ': ' + headers.get(header));
                }
            }
            if (timeout != null) {
                request.setTimeout(timeout);
            }
            request.setBody(json);
            System.debug('-WS-URL: ["' + urlEndPoint + '"]');
            System.debug('-WS-ENVIO: ' + json);
            response = http.send(request);

            if (response != null) {
                System.debug('-WS-ESTADO: ["Code": "' + response.getStatusCode() + '", "Status": "' + response.getStatus() + '"]');
                System.debug('-WS-response: ' + response.getBody());
            } else {
                throw new RestServiceException('Invalid WS Response: ' + response);
            }
        } catch (Exception e) {
            System.debug('Unexpected issue: ' + e.getMessage());
            throw new RestServiceException('Unexpected issue: ' + e.getMessage());
        }
        return  response;
    }


    public static String getGeneralEndpoint () {
        return URI + '?code=' + CODE;
    }
}