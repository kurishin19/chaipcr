#include "pcrincludes.h"
#include "boostincludes.h"
#include "pocoincludes.h"
#include "utilincludes.h"
#include "controlincludes.h"

#include "testcontrolhandler.h"

using namespace std;
using namespace boost::property_tree;
using namespace Poco::Net;

void TestControlHandler::createData(const ptree &requestPt, ptree &)
{
    double ledIntensity = requestPt.get<double>("ledIntensity", -1);
    int fanRPM = requestPt.get<int>("fanRPM", -1);
    double heatSinkTargetTemp = requestPt.get<double>("heatSinkTargetTemp", -1);
    double heatBlockTargetTemp = requestPt.get<double>("heatBlockTargetTemp", -1);
    double lidTargetTemp = requestPt.get<double>("lidTargetTemp", -1);
    int activateLED = requestPt.get<int>("activateLED", -1);
    int disableLEDs = requestPt.get<int>("disableLEDs", -1);
    bool collectData = requestPt.get<bool>("collectData", false);

    if (ledIntensity != -1)
    {
        shared_ptr<Optics> instance = OpticsInstance::getInstance();
        if (instance)
            instance->getLedController()->setIntensity(ledIntensity);
    }

    if (fanRPM != -1)
    {
        shared_ptr<HeatSink> instance = HeatSinkInstace::getInstance();
        if (instance)
            instance->setTargetRPM(fanRPM);
    }

    if (heatSinkTargetTemp != -1)
    {
        shared_ptr<HeatSink> instance = HeatSinkInstace::getInstance();
        if (instance)
            instance->setTargetTemperature(heatSinkTargetTemp);
    }

    if (heatBlockTargetTemp != -1)
    {
        shared_ptr<HeatBlock> instance = HeatBlockInstance::getInstance();
        if (instance)
            instance->setTargetTemperature(heatBlockTargetTemp);
    }

    if (lidTargetTemp != -1)
    {
        shared_ptr<Lid> instance = LidInstance::getInstance();
        if (instance)
            instance->setTargetTemperature(lidTargetTemp);
    }

    if (activateLED != -1)
    {
        shared_ptr<Optics> instance = OpticsInstance::getInstance();
        if (instance)
            instance->getLedController()->activateLED(activateLED);
    }

    shared_ptr<Optics> optics = OpticsInstance::getInstance();
    if (disableLEDs != -1)
    {
        if (optics)
            optics->getLedController()->disableLEDs();
    }
    optics->setCollectData(collectData);
}
