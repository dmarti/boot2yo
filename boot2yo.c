#include <stdio.h>
#include <curl/curl.h>

#define YO_API "http://www.justyo.co/yoall/"
#define YO_KEY "xxxxxxxxxxxxxxxxxxxx"

int main(int argc, char *argv[])
{
	CURL *curl;
	CURLcode res;
	curl_global_init(CURL_GLOBAL_NOTHING);
	char postdata [1024];
	curl = curl_easy_init();

	/* Endpoint for Yo API */
	curl_easy_setopt(curl, CURLOPT_URL, YO_API);
	/* POST data */ 
	sprintf(postdata, "api_token=%s", YO_KEY);
	curl_easy_setopt(curl, CURLOPT_POSTFIELDS, postdata);
 
    	res = curl_easy_perform(curl);
	if(res == CURLE_OK) {
		printf("SENT YO!");
	} else {
		fprintf(stderr, "FAILED! DO YOU HAVE INTERNET?");
	}
	curl_easy_cleanup(curl);
	curl_global_cleanup();
}
