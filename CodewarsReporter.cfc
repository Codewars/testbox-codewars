/**
 * Renders TestResult from TestBox in Codewars format.
 * Based on `CLIRenderer@testbox-commands`.
 */
component {

	/**
	 * @testData test results from TestBox
	 */
	function render( testData ){
		for ( thisBundle in testData.bundleStats ) {
			// Check if the bundle threw a global exception
			if ( !isSimpleValue( thisBundle.globalException ) ) {
				var message = escapeLF(
					"#thisBundle.globalException.type#:#thisBundle.globalException.message#:#thisBundle.globalException.detail#"
				);
				printLine( prependLF( "<ERROR::>#message#" ) );

				// ACF has an array for the stack trace
				if ( isSimpleValue( thisBundle.globalException.stacktrace ) ) {
					printLine( prependLF( "<LOG::-Stacktrace>#escapeLF( thisBundle.globalException.stacktrace )#" ) );
				}
			}

			var debugMap = prepareDebugBuffer( thisBundle.debugBuffer );

			// Generate reports for each suite
			for ( var suiteStats in thisBundle.suiteStats ) {
				genSuiteReport( suiteStats = suiteStats, bundleStats = thisBundle, debugMap = debugMap );
			}
		}
	}

	/**
	 * Recursive Output for suites
	 * @suiteStats Suite stats
	 * @bundleStats Bundle stats
	 */
	function genSuiteReport( required suiteStats, required bundleStats, debugMap={}, labelPrefix='' ){
		labelPrefix &= '/' & arguments.suiteStats.name;
		printLine( prependLF( "<DESCRIBE::>#arguments.suiteStats.name#" ) );

		for ( local.thisSpec in arguments.suiteStats.specStats ) {
			var thisSpecLabel = labelPrefix & '/' & local.thisSpec.name;
			printLine( prependLF( "<IT::>#local.thisSpec.name#" ) );

			if( debugMap.keyExists( thisSpecLabel ) ) {
				printLine( debugMap[ thisSpecLabel ] )
			}

			if ( local.thisSpec.status == "passed" ) {
				printLine( prependLF( "<PASSED::>Test Passed" ) );
			} else if ( local.thisSpec.status == "failed" ) {
				printLine( prependLF( "<FAILED::>#escapeLF( local.thisSpec.failMessage )#" ) );
			} else if ( local.thisSpec.status == "skipped" ) {
				printLine( prependLF( "<FAILED::>Test Skipped" ) );
			} else if ( local.thisSpec.status == "error" ) {
				printLine( prependLF( "<ERROR::>#escapeLF( local.thisSpec.error.message )#" ) );

				var errorStack = [];
				// If there's a tag context, show the file name and line number where the error occurred
				if (
					isDefined( "local.thisSpec.error.tagContext" ) && isArray( local.thisSpec.error.tagContext ) && local.thisSpec.error.tagContext.len()
				) {
					errorStack = thisSpec.error.tagContext;
				} else if (
					isDefined( "local.thisSpec.failOrigin" ) && isArray( local.thisSpec.failOrigin ) && local.thisSpec.failOrigin.len()
				) {
					errorStack = thisSpec.failOrigin;
				}

				if ( errorStack.len() ) {
					var stacktrace = errorStack
						.slice( 1, 5 )
						.map( function( item ){
							return "at #item.template#:#item.line#";
						} )
						.toList( "<:LF:>" );
					printLine( prependLF( "<LOG::-Stacktrace>#stacktrace#" ) );
				}
			} else {
				printLine( prependLF( "<ERROR::>Unknown test status: #local.thisSpec.status#" ) );
			}

			printLine( prependLF( "<COMPLETEDIN::>#local.thisSpec.totalDuration#" ) );
		}

		// Handle nested Suites
		if ( arguments.suiteStats.suiteStats.len() ) {
			for ( local.nestedSuite in arguments.suiteStats.suiteStats ) {
				genSuiteReport( local.nestedSuite, arguments.bundleStats, debugMap, labelPrefix )
			}
		}

		printLine( prependLF( "<COMPLETEDIN::>#arguments.suiteStats.totalDuration#" ) );
	}

	private function escapeLF( required text ){
		return replace( text, chr( 10 ), "<:LF:>", "all" );
	}

	private function prependLF( required text ){
		return "#chr( 10 )##text#";
	}

	// Transofrm array of messages to struct keyed on message label containing an array of 
	private function prepareDebugBuffer( array debugBuffer ) {
		return debugBuffer.reduce( ( debugMap={}, d )=> {
			debugMap[ d.label ] = debugMap[ d.label ] ?: '';
			debugMap[ d.label ] &= prependLF( isSimpleValue( d.data ) ? d.data : serialize( d.data ) );
			return debugMap;
		} ) ?: {};

	}

	private function printLine( string str ) {
		systemoutput( str, 1 );
	}

}
