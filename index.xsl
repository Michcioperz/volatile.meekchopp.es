<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml">
  <xsl:output method="xml" indent="yes" encoding="UTF-8" />
  <xsl:template match="/feed">
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width" />
      </head>
      <body>
        <ul>
          <xsl:apply-templates select="entry">
          </xsl:apply-templates>
        </ul>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="entry">
    <li>
      <xsl:value-of select="updated"></xsl:value-of>
      <br />
      <xsl:value-of select="content"></xsl:value-of>
    </li>
  </xsl:template>
</xsl:stylesheet>
