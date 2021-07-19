#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May 30 13:04:33 2019
"""
# !pip install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib oauth2client

# GA
# https://stackoverflow.com/questions/12837748/analytics-google-api-error-403-user-does-not-have-any-google-analytics-account
# https://stackoverflow.com/questions/59451776/parsing-google-api-object-into-pandas-dataframe
# https://developers.google.com/analytics/devguides/reporting/core/v4
#
# GSC
# https://developers.google.com/search/apis/indexing-api/v3/using-api?hl=tr
# https://developers.google.com/search/apis/indexing-api/v3/prereqs?hl=tr
# https://developers.google.com/webmaster-tools/search-console-api-original/v3/quickstart/quickstart-python

import pandas as pd
import os
from googleapiclient.discovery import build
from oauth2client.service_account import ServiceAccountCredentials


class ContentReport:
    def __init__(self, dir=os.getcwd(), keyFile=None):

        self.dir, self.getKeyFile = dir, '{}/{}'.format(dir, keyFile)
        self.credentials, self.domain, self.fileName = None, None, None
        self.scopes = []
        self.dateRanges, self.GA_BODY, self.GSC_BODY = {}, {}, {}

    def setCredentials(self):
        if os.path.exists(self.getKeyFile):
            self.credentials = (
                ServiceAccountCredentials
                .from_json_keyfile_name(self.getKeyFile, self.scopes))
        else:
            print('Credential file not found')

    def getCredentials(self):
        self.setCredentials()
        return self.credentials

    def setScopes(self, scope=['https://www.googleapis.com/auth/analytics.readonly']):
        self.scopes = scope

    def getScopes(self):
        return self.scopes

    def setDateRange(self, startDate='7DaysAgo', endDate='today'):
        self.dateRanges['startDate'] = startDate
        self.dateRanges['endDate'] = endDate

    def getDateRange(self):
        return self.dateRanges

    def setGA(self, viewId, metrics='pageviews', dimensions='pagePath', orderBy='pageviews', segment='gaid::-3'):

        prefix = 'ga'

        self.GA_BODY = {
            'reportRequests': [{
                'viewId': viewId,
                'dateRanges': self.dateRanges,
                'metrics': [{'expression': '{}:{}'.format(prefix, i), 'alias': i} for i in metrics],
                'dimensions': [{'name': '{}:{}'.format(prefix, i)} for i in dimensions],
                'orderBys': [{
                    "fieldName": '{}:{}'.format(prefix, orderBy),
                    "orderType": 'VALUE',
                    "sortOrder": 'DESCENDING'
                }],
                # "segments": [{
                #    "segmentId": segment
                # }],
                "samplingLevel": "LARGE",
                # "pageToken": "10000",
                "pageSize": 10000,
            }],
        }

    def getGA(self, export=False):

        def print_response(response):
            list = []

            for report in response.get('reports', []):
                columnHeader = report.get('columnHeader', {})
                dimensionHeaders = columnHeader.get('dimensions', [])
                metricHeaders = columnHeader.get(
                    'metricHeader', {}).get('metricHeaderEntries', [])

                for row in report.get('data', {}).get('rows', []):
                    dict = {}

                    for header, dimension in zip(dimensionHeaders, row.get('dimensions', [])):
                        dict[header] = dimension

                    for i, values in enumerate(row.get('metrics', [])):
                        for metric, value in zip(metricHeaders, values.get('values')):
                            if ',' in value or '.' in value:
                                dict[metric.get('name')] = float(value)
                            else:
                                dict[metric.get('name')] = int(value)

                    list.append(dict)
                return pd.DataFrame(list)

        try:
            print('Working on the GA API request...')
            GA_response = (
                build('analyticsreporting', 'v4',
                      credentials=self.getCredentials())
                .reports()
                .batchGet(body=self.GA_BODY)
                .execute())
        except Exception as e:
            print('Error: {}'.format(e))

        df = (
            print_response(GA_response)
            .rename(columns={
                'ga:pagePath': 'PagePath',
                'ga:pageTitle': 'PageTitle'
            }))

        if export is True:
            self.saveAsCSV(fileName='GA', data=df)
        else:
            print(df)

    def setGSC(self, domain, dimensions=['query', 'page']):
        self.domain = domain
        self.GSC_BODY = {
            'startDate': self.dateRanges['startDate'],
            'endDate': self.dateRanges['endDate'],
            'dimensions': dimensions,
            'rowLimit': 10000
        }

    def getGSC(self, export=False):
        # redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
        try:
            print('Working on the GSC API request...')
            GSC_response = (
                build('webmasters', 'v3', credentials=self.getCredentials())
                .searchanalytics()
                .query(siteUrl=self.domain, body=self.GSC_BODY)
                .execute())
            df = pd.json_normalize(GSC_response['rows'])

            for i, d in enumerate(self.GSC_BODY['dimensions']):
                df[d] = df['keys'].apply(lambda x: x[i])

            df.drop(columns='keys', inplace=True)
            if export is True:
                self.saveAsCSV(fileName='GSC', data=df)
            else:
                print(df)
        except Exception as e:
            print('Error: {}'.format(e))

    def saveAsCSV(self, fileName, data):
        self.fileName = (
            '{}/{}-{}.csv'
            .format(self.dir, fileName, self.dateRanges['startDate']))
        try:
            if os.path.exists(self.fileName):
                os.remove(self.fileName)
            data.to_csv(self.fileName, index=False)
            if os.path.exists(self.fileName):
                print('{} has been successfully created!'.format(self.fileName))
        except Exception as e:
            print('Error: {}'.format(e))


def main():

    try:
        data = ContentReport(dir='/Users/ceaksan/Desktop/PageContentAnalysis/Python/Content',
                             keyFile='credentials.json')

        data.setScopes(['https://www.googleapis.com/auth/analytics.readonly',
                        'https://www.googleapis.com/auth/webmasters.readonly'])

        data.setDateRange('2020-05-30', '2021-05-30')
        data.setGA(
            viewId='109466096',
            metrics=['bounceRate', 'pageviews', 'avgTimeOnPage',
                     'avgSessionDuration', 'avgPageLoadTime'],
            dimensions=['pagePath', 'pageTitle'],
            orderBy='pageviews',
            segment='gaid::-3')

        data.setGSC(
            domain='https://ceaksan.com',
            dimensions=['query', 'page'])

        data.getGA(export=True)
        data.getGSC(export=True)

    except Exception as e:
        print('Error: {}'.format(e))


if __name__ == '__main__':
    main()
