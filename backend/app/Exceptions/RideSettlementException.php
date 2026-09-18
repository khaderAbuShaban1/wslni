<?php

namespace App\Exceptions;

use DomainException;

/** A ride that cannot be settled. The message is shown to the user as is. */
class RideSettlementException extends DomainException
{
}
